import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/core/providers/notification_providers.dart';
import 'package:moss/core/theme/app_theme.dart';
import 'package:moss/features/today/presentation/screens/matrix_tasks_screen.dart';
import 'package:moss/features/today/presentation/today_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/test_database.dart';

class _NoopNotificationClient implements INotificationClient {
  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async => true;

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
  setUpAll(tz_data.initializeTimeZones);

  Future<void> pumpMatrix(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async => await tester.binding.setSurfaceSize(null));
    final database = await tester.runAsync(createTestDatabase);
    final notificationService = NotificationService(
      client: _NoopNotificationClient(),
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
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: MatrixTasksScreen(onOpenTask: (_) {}, onAddTask: () {}),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  testWidgets('filter controls fit at 150 percent text scale', (tester) async {
    await pumpMatrix(tester, size: const Size(390, 844), textScale: 1.5);

    expect(tester.takeException(), isNull);
    expect(find.text('สวัสดี!'), findsOneWidget);
    expect(find.textContaining('เมทริกซ์'), findsOneWidget);
    expect(find.textContaining('ทำแล้ว'), findsOneWidget);
    expect(find.bySemanticsLabel('มุมมองตาราง'), findsOneWidget);
    expect(find.bySemanticsLabel('มุมมองรายการ'), findsOneWidget);
  });

  testWidgets('landscape keeps all four matrix quadrants usable', (
    tester,
  ) async {
    await pumpMatrix(tester, size: const Size(844, 390));

    expect(tester.takeException(), isNull);
    expect(find.text('สำคัญและเร่งด่วน'), findsOneWidget);
    expect(find.text('สำคัญ'), findsOneWidget);
    expect(find.text('เร่งด่วน'), findsOneWidget);
    expect(find.text('สักวันหนึ่ง'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });
}
