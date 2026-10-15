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

  testWidgets('HomeScreen renders adaptive navigation and empty agenda', (
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

    expect(find.text('วันนี้'), findsWidgets);
    expect(find.text('งานเข้า'), findsOneWidget);
    expect(find.text('โปรเจกต์'), findsOneWidget);
    expect(find.text('วันนี้ยังว่าง'), findsOneWidget);
    await disposeTestDatabase(tester, database);
  });

  testWidgets('inbox quick add persists and renders the task', (tester) async {
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

    await tester.tap(find.text('งานเข้า'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ส่งสรุปให้ลูกค้า');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await settleDatabaseIo(tester);

    expect(find.text('ส่งสรุปให้ลูกค้า'), findsOneWidget);
    await disposeTestDatabase(tester, database);
  });

  testWidgets('compact layout handles large text and a worst-case task title', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await settleDatabaseIo(tester);

    await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
    await tester.pumpAndSettle();
    const longTitle =
        'Client follow-up — ทีมกรุงเทพฯ 🚀 '
        'averyveryveryveryveryverylongunbreakableidentifier@example.com';
    await tester.enterText(find.byType(TextField), longTitle);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await settleDatabaseIo(tester);

    expect(find.text(longTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeTestDatabase(tester, database);
  });
}
