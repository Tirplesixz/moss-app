import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/core/providers/notification_providers.dart';
import 'package:moss/core/theme/app_theme.dart';
import 'package:moss/features/today/presentation/screens/home_screen.dart';
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
  setUpAll(tz.initializeTimeZones);

  testWidgets('HomeScreen renders real empty state and quick add', (
    tester,
  ) async {
    final database = await createTestDatabase();
    final notificationService = NotificationService(
      client: FakeNotificationClient(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await settleDatabaseIo(tester);

    expect(find.text('Moss'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    await disposeTestDatabase(tester, database);
  });

  testWidgets('quick add previews changes and persists after confirmation', (
    tester,
  ) async {
    final database = await createTestDatabase();
    final notificationService = NotificationService(
      client: FakeNotificationClient(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await settleDatabaseIo(tester);

    await tester.enterText(find.byType(TextField), 'ส่งสรุปให้ลูกค้า');
    await tester.tap(find.byIcon(Icons.add_rounded));
    await settleDatabaseIo(tester);

    expect(find.text('จัดตารางใหม่แล้ว'), findsOneWidget);
    expect(find.text('ส่งสรุปให้ลูกค้า'), findsOneWidget);
    await tester.tap(find.text('ตกลง ใช้ตารางนี้'));
    await settleDatabaseIo(tester);

    expect(find.text('ส่งสรุปให้ลูกค้า'), findsOneWidget);
    expect(find.text('เลิกทำ'), findsOneWidget);
    await disposeTestDatabase(tester, database);
  });
}
