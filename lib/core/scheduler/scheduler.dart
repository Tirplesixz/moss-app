import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../utils/time_utils.dart';
import '../../features/tasks/domain/task.dart';
import '../../features/tasks/domain/block.dart';
import '../../features/settings/domain/app_settings.dart';

/// Result returned by the pure scheduler function.
@immutable
class ScheduleResult {
  final List<Block> blocks;
  final List<Task> overflow;

  const ScheduleResult({required this.blocks, required this.overflow});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleResult &&
          listEquals(blocks, other.blocks) &&
          listEquals(overflow, other.overflow);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(blocks), Object.hashAll(overflow));
}

@immutable
class BlockMove {
  final String blockId;
  final String taskId;
  final String title;
  final DateTime from;
  final DateTime to;

  const BlockMove({
    required this.blockId,
    required this.taskId,
    required this.title,
    required this.from,
    required this.to,
  });
}

@immutable
class ScheduleDiff {
  final List<Block> added;
  final List<BlockMove> moved;
  final List<Block> unchanged;
  final List<Task> overflow;

  const ScheduleDiff({
    this.added = const [],
    this.moved = const [],
    this.unchanged = const [],
    this.overflow = const [],
  });
}

@immutable
class UrgentScheduleResult {
  final Task newTask;
  final List<Block> proposal;
  final ScheduleDiff diff;

  const UrgentScheduleResult({
    required this.newTask,
    required this.proposal,
    required this.diff,
  });
}

/// Pure scheduler functions as specified in PLAN.md Section 6.
/// No DB access, no DateTime.now() inside (pass `now` in).
/// Same input always produces the exact same output.
class Scheduler {
  Scheduler._();

  static const _uuid = Uuid();

  /// Orders tasks according to PLAN.md Section 6.1:
  /// deadline ascending (no deadline last) -> priority descending -> createdAt ascending.
  static int compareTasks(Task a, Task b) {
    // 1. Deadline ascending (no deadline last)
    if (a.deadlineAt != null && b.deadlineAt != null) {
      final cmp = a.deadlineAt!.compareTo(b.deadlineAt!);
      if (cmp != 0) return cmp;
    } else if (a.deadlineAt != null && b.deadlineAt == null) {
      return -1;
    } else if (a.deadlineAt == null && b.deadlineAt != null) {
      return 1;
    }

    // 2. Priority descending (3 > 2 > 1)
    final prioCmp = b.priority.compareTo(a.priority);
    if (prioCmp != 0) return prioCmp;

    // 3. CreatedAt ascending
    return a.createdAt.compareTo(b.createdAt);
  }

  /// Schedules tasks into available slots over an 8-day horizon (today + next 7 days).
  ///
  /// [tasks]: Only 'todo' and non-deleted tasks are considered.
  /// [fixedBlocks]: Pre-existing fixed or locked blocks that cannot be moved.
  /// [settings]: Workday start/end times and buffer.
  /// [now]: Current time in UTC.
  static ScheduleResult schedule({
    required List<Task> tasks,
    required List<Block> fixedBlocks,
    required AppSettings settings,
    required DateTime now,
  }) {
    final nowUtc = now.toUtc();
    final nowLocal = nowUtc.toLocal();

    // 1. Consider only tasks with status 'todo' and not soft-deleted
    final candidateTasks = tasks
        .where((t) => t.status == TaskStatus.todo && !t.isDeleted)
        .toList();

    // 2. Order tasks by deadline ASC -> priority DESC -> createdAt ASC
    candidateTasks.sort(compareTasks);

    // Keep existing fixed or locked blocks
    final activeFixedBlocks = fixedBlocks
        .where((b) => (b.isFixed || b.locked) && !b.isDeleted)
        .toList();

    // All scheduled blocks so far (starts with fixed/locked blocks)
    final allOccupiedBlocks = List<Block>.from(activeFixedBlocks);
    final scheduledTaskBlocks = <Block>[];
    final overflowTasks = <Task>[];

    // Parse workday start and end hours/minutes
    final startParts = settings.workdayStart.split(':');
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);

    final endParts = settings.workdayEnd.split(':');
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    final bufferMinutes = settings.bufferMin;

    for (final task in candidateTasks) {
      Block? placedBlock;

      // Horizon: today + next 7 days (8 days total: dayOffset 0..7)
      for (int dayOffset = 0; dayOffset <= 7; dayOffset++) {
        final currentLocalDate = DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day,
        ).add(Duration(days: dayOffset));

        final workdayStartLocal = DateTime(
          currentLocalDate.year,
          currentLocalDate.month,
          currentLocalDate.day,
          startHour,
          startMinute,
        );

        final workdayEndLocal = DateTime(
          currentLocalDate.year,
          currentLocalDate.month,
          currentLocalDate.day,
          endHour,
          endMinute,
        );

        final workdayStartUtc = workdayStartLocal.toUtc();
        final workdayEndUtc = workdayEndLocal.toUtc();

        // Earliest possible start time for this day
        DateTime candidateSlotStart;
        if (dayOffset == 0) {
          final roundedNow = TimeUtils.roundUpToInterval(
            nowUtc,
            minuteInterval: 5,
          );
          candidateSlotStart = roundedNow.isAfter(workdayStartUtc)
              ? roundedNow
              : workdayStartUtc;
        } else {
          candidateSlotStart = workdayStartUtc;
        }

        // Search for a free slot within this workday
        while (true) {
          final candidateSlotEnd = candidateSlotStart.add(
            Duration(minutes: task.durationMin),
          );

          // Must lie inside the workday window
          if (candidateSlotEnd.isAfter(workdayEndUtc)) {
            // Cannot fit on this day; break to next day
            break;
          }

          // Must end at or before deadlineAt if one exists
          if (task.deadlineAt != null &&
              candidateSlotEnd.isAfter(task.deadlineAt!)) {
            // Exceeds deadline; this task will never fit in this or future slots
            break;
          }

          // Check overlap with any already placed block (fixed or task)
          // We also consider buffer: if a block is placed, any subsequent block should
          // start after previous block's endAt + bufferMin.
          Block? overlappingBlock;
          for (final occ in allOccupiedBlocks) {
            // Check if occ overlaps [candidateSlotStart, candidateSlotEnd]
            final bool overlaps =
                candidateSlotStart.isBefore(occ.endAt) &&
                candidateSlotEnd.isAfter(occ.startAt);
            if (overlaps) {
              overlappingBlock = occ;
              break;
            }

            // Also check if candidateSlot starts too close after a task block (buffer check)
            if (candidateSlotStart.isBefore(
                  occ.endAt.add(Duration(minutes: bufferMinutes)),
                ) &&
                candidateSlotStart.isAfter(occ.startAt)) {
              overlappingBlock = occ;
              break;
            }
          }

          if (overlappingBlock != null) {
            // Push candidateSlotStart to after the overlapping block + buffer (rounded to 5 min)
            final nextPossible = overlappingBlock.endAt.add(
              Duration(minutes: bufferMinutes),
            );
            candidateSlotStart = TimeUtils.roundUpToInterval(
              nextPossible,
              minuteInterval: 5,
            );
            continue;
          }

          // Slot found!
          placedBlock = Block(
            id: _uuid.v4(),
            kind: BlockKind.task,
            taskId: task.id,
            title: task.title,
            startAt: candidateSlotStart,
            endAt: candidateSlotEnd,
            locked: false,
            source: 'local',
            createdAt: nowUtc,
            updatedAt: nowUtc,
          );
          break;
        }

        if (placedBlock != null) {
          break;
        }

        // If task has a deadline and workdayStart of next day is already after deadline,
        // it cannot be scheduled on subsequent days.
        if (task.deadlineAt != null) {
          final nextDayStartLocal = workdayStartLocal.add(
            const Duration(days: 1),
          );
          if (nextDayStartLocal.toUtc().isAfter(task.deadlineAt!)) {
            break;
          }
        }
      }

      if (placedBlock != null) {
        scheduledTaskBlocks.add(placedBlock);
        allOccupiedBlocks.add(placedBlock);
      } else {
        overflowTasks.add(task);
      }
    }

    return ScheduleResult(blocks: scheduledTaskBlocks, overflow: overflowTasks);
  }

  /// Builds an explainable proposal for an urgent task. Existing blocks are
  /// compared by task id so the UI can show only additions and movements.
  static UrgentScheduleResult insertUrgent({
    required List<Block> currentBlocks,
    required List<Task> currentTasks,
    required Task newTask,
    required List<Block> fixedBlocks,
    required AppSettings settings,
    required DateTime now,
  }) {
    final result = schedule(
      tasks: [...currentTasks, newTask],
      fixedBlocks: fixedBlocks,
      settings: settings,
      now: now,
    );

    final oldByTaskId = <String, Block>{
      for (final block in currentBlocks)
        if (block.taskId != null) block.taskId!: block,
    };
    final added = <Block>[];
    final moved = <BlockMove>[];
    final unchanged = <Block>[];

    for (final block in result.blocks) {
      if (block.taskId == newTask.id) {
        added.add(block);
        continue;
      }
      final old = oldByTaskId[block.taskId];
      if (old == null) continue;
      if (old.startAt == block.startAt && old.endAt == block.endAt) {
        unchanged.add(block);
      } else {
        moved.add(
          BlockMove(
            blockId: old.id,
            taskId: block.taskId!,
            title: old.title ?? block.title ?? 'งาน',
            from: old.startAt,
            to: block.startAt,
          ),
        );
      }
    }

    return UrgentScheduleResult(
      newTask: newTask,
      proposal: result.blocks,
      diff: ScheduleDiff(
        added: added,
        moved: moved,
        unchanged: unchanged,
        overflow: result.overflow,
      ),
    );
  }
}
