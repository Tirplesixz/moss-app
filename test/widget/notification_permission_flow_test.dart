import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/core/providers/notification_providers.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/core/theme/app_theme.dart';
import 'package:moss/features/today/presentation/screens/home_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../helpers/test_database.dart';

class MockNotificationClient implements INotificationClient {
  bool requestPermissionCalled = false;
  int zonedScheduleCallCount = 0;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    return true;
  }

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
  }) async {
    zonedScheduleCallCount++;
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    requestPermissionCalled = true;
    return true;
  }

  @override
  Future<bool?> requestIosPermission() async {
    requestPermissionCalled = true;
    return true;
  }
}

void main() {
  tz.initializeTimeZones();

  testWidgets(
    'Notification permission is requested after first task is added, not on first launch',
    (WidgetTester tester) async {
      final mockClient = MockNotificationClient();
      final mockNotifService = NotificationService(client: mockClient);
      final database = await createTestDatabase();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            notificationServiceProvider.overrideWithValue(mockNotifService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await settleDatabaseIo(tester);

      // 1. On first launch, permission should NOT be requested yet (PLAN.md Section 9)
      expect(mockClient.requestPermissionCalled, isFalse);

      // 2. Add first task from the inbox composer
      await tester.tap(find.text('งานเข้า'));
      await tester.pumpAndSettle();
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'งานชิ้นแรก');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await settleDatabaseIo(tester);

      // 3. Permission MUST have been requested after first task was added!
      expect(mockClient.requestPermissionCalled, isTrue);
      // 4. Notifications should have been scheduled
      expect(mockClient.zonedScheduleCallCount, greaterThan(0));
      await disposeTestDatabase(tester, database);
    },
  );
}
