import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/analytics/event_log_repository.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/scheduler/scheduler.dart';
import '../../../core/utils/time_utils.dart';
import '../../settings/data/settings_repository.dart';
import '../../lockscreen/data/lockscreen_sync_service.dart';
import '../../calendar/data/calendar_task_sync_service.dart';
import '../../settings/domain/app_settings.dart';
import '../../tasks/data/block_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/block.dart';
import '../../tasks/domain/task.dart';
import '../domain/today_item.dart';
import 'today_state.dart';

class TodayController extends StateNotifier<TodayState> {
  TodayController({
    required TaskRepository taskRepository,
    required BlockRepository blockRepository,
    required SettingsRepository settingsRepository,
    required NotificationService notificationService,
    required EventLogRepository eventLogRepository,
    LockScreenSyncService? lockScreenSyncService,
    CalendarTaskSyncService? calendarTaskSyncService,
    bool enableTicker = true,
  }) : _taskRepository = taskRepository,
       _blockRepository = blockRepository,
       _settingsRepository = settingsRepository,
       _notificationService = notificationService,
       _eventLogRepository = eventLogRepository,
       _lockScreenSyncService = lockScreenSyncService,
       _calendarTaskSyncService = calendarTaskSyncService,
       super(
         TodayState(currentDate: _localDay(DateTime.now()), isLoading: true),
       ) {
    unawaited(load());
    if (enableTicker) {
      _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    }
  }

  static const _uuid = Uuid();

  final TaskRepository _taskRepository;
  final BlockRepository _blockRepository;
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;
  final EventLogRepository _eventLogRepository;
  final LockScreenSyncService? _lockScreenSyncService;
  final CalendarTaskSyncService? _calendarTaskSyncService;

  AppSettings _settings = AppSettings.createDefault();
  Map<String, Task> _tasksById = const {};
  Timer? _ticker;
  bool _hasRequestedPermission = false;
  _UndoSnapshot? _undoSnapshot;
  UndoableAction? _lastAction;

  bool get hasRequestedPermission => _hasRequestedPermission;
  AppSettings get settings => _settings;

  static DateTime _localDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      await _notificationService.initialize();
      _settings = await _settingsRepository.getSettings();
      if (_settings.saveCompletedToCalendar) {
        await _calendarTaskSyncService?.syncAllTodoTasks();
      }
      await _refreshFromDatabase();
      await _eventLogRepository.track('app_open');
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'โหลดตารางไม่สำเร็จ กรุณาลองอีกครั้ง',
      );
    }
  }

  Future<void> _refreshFromDatabase({List<Task>? overflow}) async {
    final now = TimeUtils.nowUtc();
    final tasks = await _taskRepository.getAllActiveTasks();
    final blocks = await _blockRepository.getActiveBlocks();
    _tasksById = {for (final task in tasks) task.id: task};

    final activeBlocks = blocks.where((block) {
      if (block.taskId == null) return true;
      return _tasksById[block.taskId]?.status == TaskStatus.todo;
    }).toList();

    final nowBlock = _findNowBlock(activeBlocks, now);
    final today = _localDay(now.toLocal());
    final upcoming = activeBlocks.where((block) {
      final localStart = block.startAt.toLocal();
      return block.id != nowBlock?.id &&
          block.endAt.isAfter(now) &&
          _localDay(localStart) == today;
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));

    final done = tasks
        .where((task) => task.status == TaskStatus.done)
        .map((task) => '${task.title} · เสร็จแล้ว')
        .toList();

    final scheduledTaskIds = activeBlocks
        .map((block) => block.taskId)
        .whereType<String>()
        .toSet();
    final calculatedOverflow = tasks
        .where(
          (task) =>
              task.status == TaskStatus.todo &&
              !scheduledTaskIds.contains(task.id),
        )
        .toList();

    state = state.copyWith(
      currentDate: today,
      isLoading: false,
      errorMessage: () => null,
      nowBlock: () => nowBlock,
      nowTask: () =>
          nowBlock?.taskId == null ? null : _tasksById[nowBlock!.taskId],
      nowProgress: _progressFor(nowBlock, now),
      nowRemainingMinutes: _remainingFor(nowBlock, now),
      doneItems: done,
      timelineItems: buildTimelineWithGaps(
        upcoming,
        tasksById: _tasksById,
        afterTime: nowBlock?.endAt ?? now,
      ),
      overflowTasks: overflow ?? calculatedOverflow,
      allTasks: tasks,
      allBlocks: activeBlocks,
    );
    final lockScreenSync = _lockScreenSyncService?.syncIfEnabled();
    if (lockScreenSync != null) {
      unawaited(lockScreenSync.then<void>((_) {}));
    }
  }

  Block? _findNowBlock(List<Block> blocks, DateTime now) {
    for (final block in blocks) {
      if (!now.isBefore(block.startAt) && now.isBefore(block.endAt)) {
        return block;
      }
    }
    return null;
  }

  double _progressFor(Block? block, DateTime now) {
    if (block == null) return 0;
    final total = block.endAt.difference(block.startAt).inSeconds;
    if (total <= 0) return 0;
    return (now.difference(block.startAt).inSeconds / total)
        .clamp(0, 1)
        .toDouble();
  }

  int _remainingFor(Block? block, DateTime now) {
    if (block == null) return 0;
    return block.endAt
        .difference(now)
        .inMinutes
        .clamp(0, block.durationMin)
        .toInt();
  }

  void _tick() {
    final now = TimeUtils.nowUtc();
    if (_localDay(now.toLocal()) != state.currentDate) {
      unawaited(load());
      return;
    }

    final block = state.nowBlock;
    if (block == null || !now.isBefore(block.endAt)) {
      unawaited(_refreshFromDatabase());
      return;
    }
    if (!state.isPaused) {
      state = state.copyWith(
        nowProgress: _progressFor(block, now),
        nowRemainingMinutes: _remainingFor(block, now),
      );
    }
  }

  static List<TodayTimelineItem> buildTimelineWithGaps(
    List<Block> blocks, {
    Map<String, Task> tasksById = const {},
    DateTime? afterTime,
  }) {
    final sorted = List<Block>.from(blocks)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final items = <TodayTimelineItem>[];
    DateTime? lastEnd = afterTime;

    for (final block in sorted) {
      if (lastEnd != null && block.startAt.difference(lastEnd).inMinutes >= 5) {
        items.add(
          TimelineGapItem(
            startAt: lastEnd,
            endAt: block.startAt,
            durationMin: block.startAt.difference(lastEnd).inMinutes,
          ),
        );
      }
      items.add(
        TimelineBlockItem(
          block: block,
          task: block.taskId == null ? null : tasksById[block.taskId],
        ),
      );
      lastEnd = block.endAt;
    }
    return items;
  }

  Future<void> _checkPermissionFlow() async {
    if (_hasRequestedPermission) return;
    _hasRequestedPermission = true;
    await _notificationService.requestPermission();
  }

  Future<ScheduleResult> _recomputeScheduleAndNotify() async {
    final now = TimeUtils.nowUtc();
    final tasks = await _taskRepository.getActiveTodoTasks();
    final allBlocks = await _blockRepository.getActiveBlocks();
    final current = _findNowBlock(allBlocks, now);

    final immovable = allBlocks
        .where(
          (block) => block.isFixed || block.locked || block.id == current?.id,
        )
        .toList();
    final currentTaskId = current?.taskId;
    final movableTasks = tasks
        .where((task) => task.id != currentTaskId)
        .toList();

    final result = Scheduler.schedule(
      tasks: movableTasks,
      fixedBlocks: immovable,
      settings: _settings,
      now: now,
    );

    await _blockRepository.replaceMovableTaskBlocks(result.blocks, now);
    final notificationBlocks = [
      ...immovable,
      ...result.blocks,
    ].where((block) => block.endAt.isAfter(now)).toList();
    await _notificationService.syncScheduleNotifications(
      blocks: notificationBlocks,
      tasks: tasks,
      now: now,
    );
    if (_settings.saveCompletedToCalendar) {
      await _calendarTaskSyncService?.syncAllTodoTasks();
    }
    await _refreshFromDatabase(overflow: result.overflow);
    return result;
  }

  Future<void> addManualTask(Task task) async {
    await _checkPermissionFlow();
    await _taskRepository.createTask(task);
    await _eventLogRepository.track('task_added');
    await _recomputeScheduleAndNotify();
  }

  Future<void> addFixedBlock(Block block) async {
    await _checkPermissionFlow();
    await _blockRepository.createBlock(block);
    await _recomputeScheduleAndNotify();
  }

  Future<void> deleteBlock(Block block) async {
    await _notificationService.cancelNotificationsForBlock(block.id);
    await _blockRepository.softDeleteBlock(block.id);
    final taskId = block.taskId;
    if (taskId != null) {
      final task = _tasksById[taskId];
      if (task != null) await _calendarTaskSyncService?.removeTask(task);
      await _taskRepository.softDeleteTask(taskId);
    }
    _lastAction = UndoableAction('ลบงานแล้ว', () async {
      await _blockRepository.restoreBlock(block.id);
      if (taskId != null) await _taskRepository.restoreTask(taskId);
    });
    await _recomputeScheduleAndNotify();
  }

  Future<void> completeCurrentTask() async {
    final block = state.nowBlock;
    if (block != null) await completeBlock(block);
  }

  Future<void> completeBlock(Block block) async {
    await _notificationService.cancelNotificationsForBlock(block.id);
    await _blockRepository.softDeleteBlock(block.id);
    final taskId = block.taskId;
    if (taskId != null) {
      await _taskRepository.setTaskStatus(taskId, TaskStatus.done);
      final task = _tasksById[taskId];
      if (_settings.saveCompletedToCalendar && task != null) {
        await _calendarTaskSyncService?.syncTask(
          task,
          completed: true,
          preferredStart: block.startAt,
          preferredEnd: block.endAt,
        );
      }
    }
    _lastAction = UndoableAction('ทำเสร็จแล้ว', () async {
      await _blockRepository.restoreBlock(block.id);
      if (taskId != null) {
        await _taskRepository.setTaskStatus(taskId, TaskStatus.todo);
      }
    });
    await _recomputeScheduleAndNotify();
  }

  Future<void> completeTask(Task task) async {
    final blocks = await _blockRepository.getActiveBlocksForTask(task.id);
    for (final block in blocks) {
      await _notificationService.cancelNotificationsForBlock(block.id);
    }
    await _blockRepository.softDeleteBlocksForTask(task.id);
    await _taskRepository.setTaskStatus(task.id, TaskStatus.done);
    await _eventLogRepository.track('task_completed');
    if (_settings.saveCompletedToCalendar) {
      await _calendarTaskSyncService?.syncTask(
        task,
        completed: true,
        preferredStart: blocks.isEmpty ? null : blocks.first.startAt,
        preferredEnd: blocks.isEmpty ? null : blocks.first.endAt,
      );
    }

    // Recurring task engine: spawn the next occurrence from a stable code.
    final repeatRule = TaskRepeatRule.fromStored(task.repeatRule);
    if (repeatRule != null) {
      var nextDeadline = task.deadlineAt ?? TimeUtils.nowUtc();
      switch (repeatRule) {
        case TaskRepeatRule.daily:
          nextDeadline = nextDeadline.add(const Duration(days: 1));
        case TaskRepeatRule.weekdays:
          do {
            nextDeadline = nextDeadline.add(const Duration(days: 1));
          } while (nextDeadline.weekday == DateTime.saturday ||
              nextDeadline.weekday == DateTime.sunday);
        case TaskRepeatRule.weekly:
          nextDeadline = nextDeadline.add(const Duration(days: 7));
        case TaskRepeatRule.monthly:
          nextDeadline = DateTime.utc(
            nextDeadline.year,
            nextDeadline.month + 1,
            nextDeadline.day,
            nextDeadline.hour,
            nextDeadline.minute,
          );
        case TaskRepeatRule.yearly:
          nextDeadline = DateTime.utc(
            nextDeadline.year + 1,
            nextDeadline.month,
            nextDeadline.day,
            nextDeadline.hour,
            nextDeadline.minute,
          );
      }

      final now = TimeUtils.nowUtc();
      final nextTask = Task(
        id: _uuid.v4(),
        title: task.title,
        note: task.note,
        durationMin: task.durationMin,
        deadlineAt: nextDeadline,
        priority: task.priority,
        quadrant: task.quadrant,
        projectName: task.projectName,
        checklist: task.checklist
            .map((item) => item.copyWith(done: false))
            .toList(),
        repeatRule: repeatRule.storageValue,
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
      );
      await _taskRepository.createTask(nextTask);
    }

    _lastAction = UndoableAction('ทำเสร็จแล้ว', () async {
      // Blocks are rebuilt by the scheduler, so only the status is restored.
      await _taskRepository.setTaskStatus(task.id, TaskStatus.todo);
    });
    await _recomputeScheduleAndNotify();
  }

  Future<void> uncompleteTask(Task task) async {
    await _taskRepository.setTaskStatus(task.id, TaskStatus.todo);
    await _eventLogRepository.track('task_uncompleted');
    _lastAction = UndoableAction('นำกลับมาทำต่อแล้ว', () async {
      await _taskRepository.setTaskStatus(task.id, TaskStatus.done);
      if (_settings.saveCompletedToCalendar) {
        await _calendarTaskSyncService?.syncTask(task, completed: true);
      }
    });
    await _recomputeScheduleAndNotify();
  }

  Future<void> updateTask(Task task) async {
    await _taskRepository.updateTask(task);
    await _eventLogRepository.track('task_updated');
    await _recomputeScheduleAndNotify();
  }

  Future<void> deleteTask(Task task) async {
    final blocks = await _blockRepository.getActiveBlocksForTask(task.id);
    for (final block in blocks) {
      await _notificationService.cancelNotificationsForBlock(block.id);
    }
    await _blockRepository.softDeleteBlocksForTask(task.id);
    await _calendarTaskSyncService?.removeTask(task);
    await _taskRepository.softDeleteTask(task.id);
    await _eventLogRepository.track('task_deleted');
    _lastAction = UndoableAction('ลบงานแล้ว', () async {
      await _taskRepository.restoreTask(task.id);
    });
    await _recomputeScheduleAndNotify();
  }

  /// The most recent complete/delete that can still be reverted.
  UndoableAction? get lastAction => _lastAction;

  /// Reverts [lastAction]. Returns false when there is nothing to undo.
  Future<bool> undoLastAction() async {
    final action = _lastAction;
    if (action == null) return false;
    _lastAction = null;
    await action.revert();
    await _eventLogRepository.track('action_undone');
    await _recomputeScheduleAndNotify();
    return true;
  }

  /// Gives the running block [minutes] more time.
  ///
  /// Returns false (and changes nothing) when the extra time would collide
  /// with a fixed appointment or a locked block.
  Future<bool> extendCurrentBlock(int minutes) async {
    final block = state.nowBlock;
    if (block == null || minutes <= 0) return false;
    final newEnd = block.endAt.add(Duration(minutes: minutes));
    final blocks = await _blockRepository.getActiveBlocks();
    final collides = blocks.any(
      (other) =>
          other.id != block.id &&
          (other.isFixed || other.locked) &&
          other.startAt.isBefore(newEnd) &&
          other.endAt.isAfter(block.endAt),
    );
    if (collides) return false;
    await _blockRepository.updateBlock(block.copyWith(endAt: newEnd));
    await _eventLogRepository.track(
      'block_extended',
      properties: {'minutes': minutes},
    );
    await _recomputeScheduleAndNotify();
    return true;
  }

  /// Persists checklist changes without re-running the scheduler.
  Future<void> updateChecklist(Task task, List<ChecklistItem> items) async {
    await _taskRepository.updateTask(task.copyWith(checklist: items));
    await _refreshFromDatabase(overflow: state.overflowTasks);
  }

  Future<void> reschedule() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      await _recomputeScheduleAndNotify();
      await _eventLogRepository.track('schedule_refreshed');
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'จัดตารางไม่สำเร็จ กรุณาลองอีกครั้ง',
      );
    }
  }

  Future<void> toggleLockBlock(Block block) async {
    await _blockRepository.updateBlock(block.copyWith(locked: !block.locked));
    await _recomputeScheduleAndNotify();
  }

  Future<void> editBlock(Block oldBlock, dynamic updatedItem) async {
    await _notificationService.cancelNotificationsForBlock(oldBlock.id);
    if (updatedItem is Block) {
      await _blockRepository.updateBlock(updatedItem);
    } else if (updatedItem is Task) {
      await _taskRepository.updateTask(updatedItem);
      await _blockRepository.softDeleteBlock(oldBlock.id);
    }
    await _recomputeScheduleAndNotify();
  }

  Future<void> quickAddTask(String title) async {
    if (title.trim().isEmpty) return;
    final now = TimeUtils.nowUtc();
    await addManualTask(
      Task(
        id: _uuid.v4(),
        title: title.trim(),
        durationMin: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<UrgentScheduleResult?> proposeUrgentTask(String title) async {
    if (title.trim().isEmpty) return null;
    final now = TimeUtils.nowUtc();
    final newTask = Task(
      id: _uuid.v4(),
      title: title.trim(),
      durationMin: 30,
      priority: 3,
      createdAt: now,
      updatedAt: now,
    );
    final tasks = await _taskRepository.getActiveTodoTasks();
    final blocks = await _blockRepository.getActiveBlocks();
    final current = _findNowBlock(blocks, now);
    final fixed = blocks
        .where(
          (block) => block.isFixed || block.locked || block.id == current?.id,
        )
        .toList();
    final movableBlocks = blocks
        .where(
          (block) =>
              block.isTask &&
              !block.locked &&
              block.id != current?.id &&
              block.endAt.isAfter(now),
        )
        .toList();
    final currentTasks = tasks
        .where((task) => task.id != current?.taskId)
        .toList();
    final proposal = Scheduler.insertUrgent(
      currentBlocks: movableBlocks,
      currentTasks: currentTasks,
      newTask: newTask,
      fixedBlocks: fixed,
      settings: _settings,
      now: now,
    );
    state = state.copyWith(urgentProposal: () => proposal);
    await _eventLogRepository.track(
      'urgent_replan_previewed',
      properties: {'moved': proposal.diff.moved.length},
    );
    return proposal;
  }

  Future<bool> confirmUrgentProposal() async {
    final proposal = state.urgentProposal;
    if (proposal == null) return false;
    await _checkPermissionFlow();
    final now = TimeUtils.nowUtc();
    final oldBlocks = (await _blockRepository.getActiveBlocks())
        .where(
          (block) =>
              block.isTask && !block.locked && block.startAt.isAfter(now),
        )
        .toList();
    _undoSnapshot = _UndoSnapshot(
      from: now,
      addedTaskId: proposal.newTask.id,
      previousBlocks: oldBlocks,
    );

    await _taskRepository.createTask(proposal.newTask);
    await _eventLogRepository.track('urgent_replan_confirmed');
    await _blockRepository.replaceMovableTaskBlocks(proposal.proposal, now);
    final activeTasks = await _taskRepository.getActiveTodoTasks();
    final activeBlocks = await _blockRepository.getActiveBlocks();
    await _notificationService.syncScheduleNotifications(
      blocks: activeBlocks,
      tasks: activeTasks,
      now: now,
    );
    await _refreshFromDatabase(overflow: proposal.diff.overflow);
    state = state.copyWith(urgentProposal: () => null, canUndo: true);
    return true;
  }

  void cancelUrgentProposal() {
    state = state.copyWith(urgentProposal: () => null);
    unawaited(_eventLogRepository.track('urgent_replan_cancelled'));
  }

  Future<void> undoLastUrgent() async {
    final snapshot = _undoSnapshot;
    if (snapshot == null) return;
    await _taskRepository.softDeleteTask(snapshot.addedTaskId);
    await _eventLogRepository.track('urgent_replan_undone');
    await _blockRepository.replaceMovableTaskBlocks(
      snapshot.previousBlocks,
      snapshot.from,
    );
    _undoSnapshot = null;
    await _refreshFromDatabase();
    state = state.copyWith(canUndo: false);
  }

  void dismissUndo() {
    _undoSnapshot = null;
    state = state.copyWith(canUndo: false);
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _settingsRepository.updateSettings(settings);
    await _eventLogRepository.track('settings_updated');
    await _recomputeScheduleAndNotify();
  }

  void togglePause() => state = state.copyWith(isPaused: !state.isPaused);

  void toggleShowAllUpcoming() =>
      state = state.copyWith(showAllUpcoming: !state.showAllUpcoming);

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final todayControllerProvider =
    StateNotifierProvider<TodayController, TodayState>((ref) {
      return TodayController(
        taskRepository: ref.watch(taskRepositoryProvider),
        blockRepository: ref.watch(blockRepositoryProvider),
        settingsRepository: ref.watch(settingsRepositoryProvider),
        notificationService: ref.watch(notificationServiceProvider),
        eventLogRepository: ref.watch(eventLogRepositoryProvider),
        lockScreenSyncService: ref.watch(lockScreenSyncServiceProvider),
        calendarTaskSyncService: ref.watch(calendarTaskSyncServiceProvider),
      );
    });

/// A reversible complete/delete, surfaced to the UI as an "Undo" snackbar.
class UndoableAction {
  const UndoableAction(this.label, this.revert);

  final String label;
  final Future<void> Function() revert;
}

class _UndoSnapshot {
  final DateTime from;
  final String addedTaskId;
  final List<Block> previousBlocks;

  const _UndoSnapshot({
    required this.from,
    required this.addedTaskId,
    required this.previousBlocks,
  });
}
