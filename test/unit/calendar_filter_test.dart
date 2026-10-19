import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/analytics/event_log_repository.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/features/calendar/data/device_calendar_service.dart';
import 'package:moss/features/calendar/domain/device_calendar_event.dart';
import 'package:moss/features/calendar/presentation/device_calendar_view_model.dart';
import 'package:moss/features/settings/data/settings_repository.dart';
import 'package:moss/features/tasks/data/block_repository.dart';
import 'package:moss/features/tasks/data/task_repository.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:moss/features/today/presentation/today_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/test_database.dart';

class _FakeDeviceCalendarService extends DeviceCalendarService {
  final List<DeviceCalendarEvent> fakeEvents;
  _FakeDeviceCalendarService(this.fakeEvents);

  @override
  Future<CalendarAccessStatus> checkAccess() async => CalendarAccessStatus.granted;

  @override
  Future<List<DeviceCalendarEvent>> fetchEvents(DateTime start, DateTime end) async =>
      fakeEvents;
}

class _NotificationClient implements INotificationClient {
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async => true;

  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<bool?> requestAndroidPermission() async => true;

  @override
  Future<bool?> requestIosPermission() async => true;

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {}
}

void main() {
  setUpAll(tz.initializeTimeZones);

  group('Calendar Filtering & Recurrence Engine Tests', () {
    test('DeviceCalendarViewModel filters events by active calendar source', () async {
      final now = DateTime.now();
      final event1 = DeviceCalendarEvent(
        id: 'ev_1',
        title: 'ประชุมงานลูกค้า',
        start: now,
        end: now.add(const Duration(hours: 1)),
        calendarName: 'Work Calendar',
      );
      final event2 = DeviceCalendarEvent(
        id: 'ev_2',
        title: 'นัดหมอฟัน',
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 3)),
        calendarName: 'Personal iCloud',
      );

      final service = _FakeDeviceCalendarService([event1, event2]);
      final vm = DeviceCalendarViewModel(service);

      await vm.checkAndLoadSilently(now);
      expect(vm.availableCalendarNames.length, 2);
      expect(vm.availableCalendarNames.contains('Work Calendar'), isTrue);
      expect(vm.availableCalendarNames.contains('Personal iCloud'), isTrue);

      // Initially both calendars are visible
      expect(vm.eventsForDay(now).length, 2);

      // Deselect Work Calendar
      vm.toggleCalendarVisibility('Work Calendar');
      expect(vm.isCalendarVisible('Work Calendar'), isFalse);
      expect(vm.isCalendarVisible('Personal iCloud'), isTrue);

      final filtered = vm.eventsForDay(now);
      expect(filtered.length, 1);
      expect(filtered.first.title, 'นัดหมอฟัน');

      // Re-enable all
      vm.showAllCalendars();
      expect(vm.eventsForDay(now).length, 2);
    });

    test('TodayController completeTask with biweekly repeatRule spawns next task in 14 days', () async {
      final database = await createTestDatabase();
      final tasks = TaskRepository(database);
      final controller = TodayController(
        taskRepository: tasks,
        blockRepository: BlockRepository(database),
        settingsRepository: SettingsRepository(database),
        notificationService: NotificationService(client: _NotificationClient()),
        eventLogRepository: EventLogRepository(database),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final now = DateTime.now().toUtc();
      final task = Task(
        id: 'task_biweekly',
        title: 'จ่ายค่าเช่ารายปักษ์',
        durationMin: 30,
        deadlineAt: now,
        repeatRule: TaskRepeatRule.biweekly.storageValue,
        createdAt: now,
        updatedAt: now,
      );

      await tasks.createTask(task);
      await controller.completeTask(task);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final allTasks = await tasks.getAllActiveTasks();
      final completed = allTasks.firstWhere((t) => t.id == 'task_biweekly');
      expect(completed.isCompleted, isTrue);

      final spawned = allTasks.firstWhere((t) => t.id != 'task_biweekly');
      expect(spawned.title, 'จ่ายค่าเช่ารายปักษ์');
      expect(spawned.isCompleted, isFalse);
      expect(spawned.repeatRule, TaskRepeatRule.biweekly.storageValue);

      // Difference should be approx 14 days (336 hours)
      final diffDays = spawned.deadlineAt!.difference(now).inDays;
      expect(diffDays, 14);
    });
  });
}
