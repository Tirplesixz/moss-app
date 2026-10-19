import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/calendar/data/device_calendar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.moss.moss/calendar');
  const service = DeviceCalendarService();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps native access and calendar events', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestAccess') return 'granted';
          if (call.method == 'fetchEvents') {
            return [
              {
                'id': 'event-1',
                'title': 'ประชุมทีม',
                'start': 1792198800000,
                'end': 1792202400000,
                'allDay': false,
                'calendarName': 'Work',
              },
            ];
          }
          return 'content://calendar/events/42';
        });

    expect(await service.requestAccess(), CalendarAccessStatus.granted);
    final events = await service.fetchEvents(
      DateTime.utc(2026, 10, 1),
      DateTime.utc(2026, 11, 1),
    );
    expect(events.single.title, 'ประชุมทีม');
    expect(events.single.calendarName, 'Work');
  });

  test('checks silent calendar access without triggering dialog', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'checkAccess') return 'granted';
          return null;
        });

    expect(await service.checkAccess(), CalendarAccessStatus.granted);
  });

  test('exports completed task through native channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'upsertTaskEvent');
          expect((call.arguments as Map)['title'], 'ส่งรายงาน');
          expect((call.arguments as Map)['completed'], isTrue);
          return 'content://calendar/events/42';
        });

    final created = await service.addCompletedTask(
      title: 'ส่งรายงาน',
      start: DateTime.utc(2026, 10, 17, 9),
      end: DateTime.utc(2026, 10, 17, 10),
    );
    expect(created, 'content://calendar/events/42');
  });

  test(
    'upserts an existing task event instead of creating a duplicate',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'upsertTaskEvent');
            final arguments = call.arguments as Map;
            expect(arguments['eventId'], '42');
            expect(arguments['title'], 'ประชุมลูกค้า');
            expect(arguments['completed'], isFalse);
            return '42';
          });

      final eventId = await service.upsertTaskEvent(
        eventId: '42',
        title: 'ประชุมลูกค้า',
        start: DateTime.utc(2026, 10, 21, 9),
        end: DateTime.utc(2026, 10, 21, 10),
      );
      expect(eventId, '42');
    },
  );
}
