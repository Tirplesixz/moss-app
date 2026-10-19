import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/calendar/data/device_calendar_service.dart';
import 'package:moss/features/calendar/presentation/device_calendar_view_model.dart';
import 'package:moss/features/tasks/domain/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.moss.moss/calendar');
  const service = DeviceCalendarService();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'checkAndLoadSilently loads events when permission is already granted',
    () async {
      final now = DateTime.now();
      final today10Am = DateTime(now.year, now.month, now.day, 10);
      final today11Am = DateTime(now.year, now.month, now.day, 11);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'checkAccess') return 'granted';
            if (call.method == 'fetchEvents') {
              return [
                {
                  'id': 'evt-1',
                  'title': 'นัดคุยกับลูกค้า A',
                  'start': today10Am.millisecondsSinceEpoch,
                  'end': today11Am.millisecondsSinceEpoch,
                  'allDay': false,
                  'calendarName': 'Google Calendar',
                  'location': 'Meeting Room 2',
                  'description': 'สรุปสัญญางวดแรก',
                },
              ];
            }
            return null;
          });

      final vm = DeviceCalendarViewModel(service);
      await vm.checkAndLoadSilently(now);

      expect(vm.hasAccess, isTrue);
      expect(vm.events.length, 1);
      expect(vm.events.first.title, 'นัดคุยกับลูกค้า A');
      expect(vm.events.first.location, 'Meeting Room 2');
      expect(vm.hasEventsOnDay(now), isTrue);

      // Test conflict detection
      // Task scheduled at 10:30 with 60 min duration (10:30 - 11:30) overlaps 10:00 - 11:00
      final conflictingTask = Task(
        id: 'task-1',
        title: 'ส่งงานตัวอย่าง',
        durationMin: 60,
        deadlineAt: today10Am.add(const Duration(minutes: 60)), // 11:00
        createdAt: now,
        updatedAt: now,
      );

      final conflict = vm.findConflict(conflictingTask);
      expect(conflict, isNotNull);
      expect(conflict!.title, 'นัดคุยกับลูกค้า A');

      // Task scheduled at 14:00 does not conflict
      final nonConflictingTask = Task(
        id: 'task-2',
        title: 'ออกกำลังกาย',
        durationMin: 60,
        deadlineAt: DateTime(now.year, now.month, now.day, 14),
        createdAt: now,
        updatedAt: now,
      );
      expect(vm.findConflict(nonConflictingTask), isNull);
    },
  );

  test('events spanning midnight appear on every overlapping day', () async {
    final start = DateTime(2026, 10, 16, 23);
    final end = DateTime(2026, 10, 18, 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'checkAccess') return 'granted';
          if (call.method == 'fetchEvents') {
            return [
              {
                'id': 'multi-day',
                'title': 'งานหลายวัน',
                'start': start.millisecondsSinceEpoch,
                'end': end.millisecondsSinceEpoch,
                'allDay': false,
                'calendarName': 'Work',
              },
            ];
          }
          return null;
        });

    final vm = DeviceCalendarViewModel(service);
    await vm.checkAndLoadSilently(DateTime(2026, 10, 17));

    expect(vm.eventsForDay(DateTime(2026, 10, 16)), hasLength(1));
    expect(vm.eventsForDay(DateTime(2026, 10, 17)), hasLength(1));
    expect(vm.eventsForDay(DateTime(2026, 10, 18)), hasLength(1));
    expect(vm.eventsForDay(DateTime(2026, 10, 19)), isEmpty);
  });

  test('a task does not conflict with its own synced calendar event', () async {
    final start = DateTime(2026, 10, 21, 9);
    final end = DateTime(2026, 10, 21, 10);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'checkAccess') return 'granted';
          if (call.method == 'fetchEvents') {
            return [
              {
                'id': '42',
                'title': 'ส่งงาน',
                'start': start.millisecondsSinceEpoch,
                'end': end.millisecondsSinceEpoch,
                'allDay': false,
                'calendarName': 'Moss',
              },
            ];
          }
          return null;
        });

    final vm = DeviceCalendarViewModel(service);
    await vm.checkAndLoadSilently(start);
    final task = Task(
      id: 'task-42',
      title: 'ส่งงาน',
      durationMin: 60,
      deadlineAt: end,
      calendarEventId: 'content://com.android.calendar/events/42',
      createdAt: start,
      updatedAt: start,
    );

    expect(vm.findConflict(task), isNull);
  });

  test('connectAndLoad executes onGranted callback and loads month when permission granted', () async {
    final now = DateTime(2026, 10, 25);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestAccess') return 'granted';
          if (call.method == 'fetchEvents') return [];
          return null;
        });

    final vm = DeviceCalendarViewModel(service);
    bool onGrantedCalled = false;
    final status = await vm.connectAndLoad(now, onGranted: () async {
      onGrantedCalled = true;
    });

    expect(status, CalendarAccessStatus.granted);
    expect(vm.hasAccess, isTrue);
    expect(onGrantedCalled, isTrue);
  });

  test('checkAndLoadSilently executes onGranted callback when already granted', () async {
    final now = DateTime(2026, 10, 25);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'checkAccess') return 'granted';
          if (call.method == 'fetchEvents') return [];
          return null;
        });

    final vm = DeviceCalendarViewModel(service);
    bool onGrantedCalled = false;
    await vm.checkAndLoadSilently(now, onGranted: () async {
      onGrantedCalled = true;
    });

    expect(vm.hasAccess, isTrue);
    expect(onGrantedCalled, isTrue);
  });
}
