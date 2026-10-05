import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/scheduler/scheduler.dart';
import 'package:moss/features/settings/domain/app_settings.dart';
import 'package:moss/features/tasks/domain/block.dart';
import 'package:moss/features/tasks/domain/task.dart';

void main() {
  final settings = AppSettings(
    id: 'settings',
    workdayStart: '09:00',
    workdayEnd: '18:00',
    bufferMin: 5,
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  test('urgent proposal reports added and moved blocks', () {
    final now = DateTime(2026, 10, 1, 9).toUtc();
    final existingTask = Task(
      id: 'existing',
      title: 'งานเดิม',
      durationMin: 60,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
    );
    final existingBlock = Block(
      id: 'existing-block',
      kind: BlockKind.task,
      taskId: existingTask.id,
      title: existingTask.title,
      startAt: now,
      endAt: now.add(const Duration(hours: 1)),
      createdAt: now,
      updatedAt: now,
    );
    final urgent = Task(
      id: 'urgent',
      title: 'งานด่วน',
      durationMin: 30,
      priority: 3,
      createdAt: now,
      updatedAt: now,
    );

    final result = Scheduler.insertUrgent(
      currentBlocks: [existingBlock],
      currentTasks: [existingTask],
      newTask: urgent,
      fixedBlocks: const [],
      settings: settings,
      now: now,
    );

    expect(result.diff.added.single.taskId, urgent.id);
    expect(result.diff.moved.single.taskId, existingTask.id);
    expect(result.diff.moved.single.from, existingBlock.startAt);
    expect(result.diff.overflow, isEmpty);
  });

  test('urgent task that cannot meet deadline is explicit overflow', () {
    final now = DateTime(2026, 10, 1, 9).toUtc();
    final urgent = Task(
      id: 'urgent-tight',
      title: 'งานด่วนที่เวลาไม่พอ',
      durationMin: 30,
      deadlineAt: now.add(const Duration(minutes: 15)),
      priority: 3,
      createdAt: now,
      updatedAt: now,
    );

    final result = Scheduler.insertUrgent(
      currentBlocks: const [],
      currentTasks: const [],
      newTask: urgent,
      fixedBlocks: const [],
      settings: settings,
      now: now,
    );

    expect(result.diff.added, isEmpty);
    expect(result.diff.overflow.single.id, urgent.id);
  });
}
