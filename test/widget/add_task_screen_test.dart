import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/core/providers/notification_providers.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/core/theme/app_theme.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:moss/features/tasks/presentation/screens/add_task_screen.dart';
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

  testWidgets('AddTaskScreen renders all fields per PLAN.md Section 7.2', (
    WidgetTester tester,
  ) async {
    Task? createdTask;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                createdTask = await AddTaskScreen.show(context);
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Check title and fields
    expect(find.text('เพิ่มงานใหม่'), findsOneWidget);
    expect(find.text('ชื่องาน'), findsOneWidget);
    expect(find.text('ใช้เวลาประมาณ'), findsOneWidget);
    expect(find.text('เดดไลน์ (ถ้ามี)'), findsOneWidget);

    // Check preset duration chips
    expect(find.text('15 นาที'), findsOneWidget);
    expect(find.text('30 นาที'), findsOneWidget);
    expect(find.text('60 นาที'), findsOneWidget);
    expect(find.text('90 นาที'), findsOneWidget);
    expect(find.text('กำหนดเอง'), findsOneWidget);

    // Check preset deadline chips
    expect(find.text('ไม่มีเดดไลน์'), findsOneWidget);
    expect(find.text('เย็นนี้ (18:00)'), findsOneWidget);
    expect(find.text('พรุ่งนี้ (18:00)'), findsOneWidget);
    expect(find.text('เลือกวันเอง...'), findsOneWidget);

    // Enter title
    await tester.enterText(
      find.descendant(
        of: find.byType(AddTaskScreen),
        matching: find.byType(TextField),
      ),
      'ส่งสไลด์ให้ลูกค้า',
    );

    // Select 60 min chip
    await tester.tap(find.text('60 นาที'));
    await tester.pumpAndSettle();

    // Select 'เย็นนี้ (18:00)' chip
    await tester.tap(find.text('เย็นนี้ (18:00)'));
    await tester.pumpAndSettle();

    // Submit
    await tester.ensureVisible(find.text('เพิ่มงานและจัดตาราง'));
    await tester.tap(find.text('เพิ่มงานและจัดตาราง'));
    await tester.pumpAndSettle();

    expect(createdTask, isNotNull);
    expect(createdTask!.title, 'ส่งสไลด์ให้ลูกค้า');
    expect(createdTask!.durationMin, 60);
    expect(createdTask!.deadlineAt, isNotNull);
    expect(createdTask!.priority, 2); // Default priority 2
  });

  testWidgets(
    'HomeScreen manual add task button opens AddTaskScreen and adds scheduled block',
    (WidgetTester tester) async {
      final fakeClient = FakeNotificationClient();
      final notifService = NotificationService(client: fakeClient);
      final database = await createTestDatabase();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            notificationServiceProvider.overrideWithValue(notifService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await settleDatabaseIo(tester);

      // Tap AppBar action "เพิ่มงานแบบละเอียด"
      await tester.tap(find.byIcon(Icons.note_add_outlined));
      await tester.pumpAndSettle();

      expect(find.text('เพิ่มงานใหม่'), findsOneWidget);

      // Type task name in AddTaskScreen and select 15 min
      final addTaskTextField = find.descendant(
        of: find.byType(AddTaskScreen),
        matching: find.byType(TextField),
      );
      await tester.enterText(addTaskTextField, 'ประชุมด่วน 15 นาที');
      await tester.tap(find.text('15 นาที'));
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('เพิ่มงานและจัดตาราง'));
      await tester.tap(find.text('เพิ่มงานและจัดตาราง'));
      await tester.pumpAndSettle();

      // Check if added to timeline
      final showAllButton = find.textContaining('ดูทั้งวัน');
      if (showAllButton.evaluate().isNotEmpty) {
        await tester.ensureVisible(showAllButton);
        await tester.tap(showAllButton);
        await tester.pumpAndSettle();
      }

      expect(find.text('ประชุมด่วน 15 นาที'), findsOneWidget);
      await disposeTestDatabase(tester, database);
    },
  );
}
