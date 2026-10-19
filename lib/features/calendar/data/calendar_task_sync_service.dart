import '../../tasks/data/block_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task.dart';
import 'device_calendar_service.dart';

/// Keeps Moss tasks and their corresponding device-calendar events aligned.
class CalendarTaskSyncService {
  CalendarTaskSyncService({
    required TaskRepository taskRepository,
    required BlockRepository blockRepository,
    DeviceCalendarService calendar = const DeviceCalendarService(),
  }) : _taskRepository = taskRepository,
       _blockRepository = blockRepository,
       _calendar = calendar;

  final TaskRepository _taskRepository;
  final BlockRepository _blockRepository;
  final DeviceCalendarService _calendar;

  Future<bool> syncTask(
    Task task, {
    bool? completed,
    DateTime? preferredStart,
    DateTime? preferredEnd,
  }) async {
    final persisted = await _taskRepository.getTaskById(task.id) ?? task;
    var start = preferredStart;
    var end = preferredEnd;

    if (start == null || end == null) {
      final blocks = await _blockRepository.getActiveBlocksForTask(task.id);
      if (blocks.isNotEmpty) {
        start = blocks.first.startAt;
        end = blocks.first.endAt;
      }
    }

    if (start == null || end == null) {
      end = persisted.deadlineAt;
      if (end != null) {
        start = end.subtract(
          Duration(
            minutes: persisted.durationMin > 0 ? persisted.durationMin : 30,
          ),
        );
      }
    }

    if (start == null || end == null) return false;
    final eventId = await _calendar.upsertTaskEvent(
      eventId: persisted.calendarEventId,
      title: persisted.title,
      start: start.toLocal(),
      end: end.toLocal(),
      completed: completed ?? persisted.isCompleted,
      notes: persisted.note,
    );
    if (eventId == null) return false;
    if (eventId != persisted.calendarEventId) {
      await _taskRepository.setCalendarEventId(task.id, eventId);
    }
    return true;
  }

  Future<void> syncAllTodoTasks() async {
    final tasks = await _taskRepository.getActiveTodoTasks();
    for (final task in tasks) {
      await syncTask(task);
    }
  }

  Future<bool> removeTask(Task task) async {
    final persisted = await _taskRepository.getTaskById(task.id);
    final eventId = persisted?.calendarEventId ?? task.calendarEventId;
    if (eventId == null) return true;
    final removed = await _calendar.deleteEvent(eventId);
    if (removed && persisted != null) {
      await _taskRepository.setCalendarEventId(task.id, null);
    }
    return removed;
  }

  Future<void> removeAllTaskEvents() async {
    final tasks = await _taskRepository.getAllActiveTasks();
    for (final task in tasks) {
      await removeTask(task);
    }
  }
}
