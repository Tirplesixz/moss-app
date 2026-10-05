import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/core/providers/notification_providers.dart';
import 'package:moss/core/theme/app_theme.dart';
import 'package:moss/features/tasks/presentation/screens/add_task_screen.dart';
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

  testWidgets('fixed block can be added and deleted', (tester) async {
    final database = await createTestDatabase();
    final notifications = NotificationService(client: FakeNotificationClient());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await settleDatabaseIo(tester);

    await tester.tap(find.byIcon(Icons.note_add_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(AddTaskScreen), findsOneWidget);

    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AddTaskScreen),
        matching: find.byType(TextField),
      ),
      'นัดคุยทีม',
    );
    await tester.ensureVisible(find.byType(ElevatedButton).last);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    expect(find.text('นัดคุยทีม'), findsOneWidget);
    await tester.tap(find.text('นัดคุยทีม'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await settleDatabaseIo(tester);
    expect(find.text('นัดคุยทีม'), findsNothing);
    await disposeTestDatabase(tester, database);
  });
}
