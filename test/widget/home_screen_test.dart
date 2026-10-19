import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/core/providers/notification_providers.dart';
import 'package:moss/features/today/presentation/today_controller.dart';
import 'package:moss/features/today/presentation/screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/test_database.dart';

class FakeNotificationClient implements INotificationClient {
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async => true;

  @override
  Future<void> cancel({required int id, String? tag}) async {}

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

  @override
  Future<bool?> requestAndroidPermission() async => true;

  @override
  Future<bool?> requestIosPermission() async => true;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz.initializeTimeZones();
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.moss.moss/calendar'),
          (call) async {
            if (call.method == 'checkAccess') return 'undetermined';
            if (call.method == 'fetchEvents') return [];
            return null;
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.moss.moss/lockscreen'),
          (call) async => {'action': 'applied'},
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.moss.moss/calendar'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.moss.moss/lockscreen'),
          null,
        );
  });

  testWidgets('HomeScreen renders 5 navigation tabs and greeting', (
    tester,
  ) async {
    final database = await tester.runAsync(createTestDatabase);
    final notificationService = NotificationService(
      client: FakeNotificationClient(),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database!),
            notificationServiceProvider.overrideWithValue(notificationService),
            todayControllerProvider.overrideWith((ref) => TodayController(
              taskRepository: ref.watch(taskRepositoryProvider),
              blockRepository: ref.watch(blockRepositoryProvider),
              settingsRepository: ref.watch(settingsRepositoryProvider),
              notificationService: notificationService,
              eventLogRepository: ref.watch(eventLogRepositoryProvider),
              enableTicker: false,
            )),
          ],
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();

    expect(find.text('สวัสดี!'), findsOneWidget);
    expect(find.text('งาน'), findsWidgets);
    expect(find.text('ปฏิทิน'), findsWidgets);
    expect(find.text('ล็อกสกรีน'), findsWidgets);
    expect(find.text('โน้ต'), findsWidgets);
    expect(find.text('ตั้งค่า'), findsWidgets);

    await disposeTestDatabase(tester, database!);
  });

  testWidgets(
    'switching tabs navigates to Calendar, Lock, Notes, and Settings',
    (tester) async {
      final database = await tester.runAsync(createTestDatabase);
      final notificationService = NotificationService(
        client: FakeNotificationClient(),
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(database!),
              notificationServiceProvider.overrideWithValue(
                notificationService,
              ),
              todayControllerProvider.overrideWith((ref) => TodayController(
                taskRepository: ref.watch(taskRepositoryProvider),
                blockRepository: ref.watch(blockRepositoryProvider),
                settingsRepository: ref.watch(settingsRepositoryProvider),
                notificationService: notificationService,
                eventLogRepository: ref.watch(eventLogRepositoryProvider),
                enableTicker: false,
              )),
            ],
            child: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: MaterialApp(home: HomeScreen()),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();

      // Switch to Calendar tab
      await tester.tap(find.text('ปฏิทิน').last);
      await settleDatabaseIo(tester);
      expect(find.text('0 รายการ'), findsOneWidget);

      // Switch to Lock tab
      await tester.tap(find.text('ล็อกสกรีน').last);
      await settleDatabaseIo(tester);
      expect(find.text('ล็อกสกรีน'), findsWidgets);

      // Switch to Notes tab
      await tester.tap(find.text('โน้ต').last);
      await settleDatabaseIo(tester);
      expect(find.text('เก็บไอเดียแยกจากงานที่ต้องลงมือทำ'), findsOneWidget);

      // Switch to Settings tab
      await tester.tap(find.text('ตั้งค่า').last);
      await settleDatabaseIo(tester);
      expect(find.text('การตั้งค่า'), findsOneWidget);

      await disposeTestDatabase(tester, database!);
    },
  );
}
