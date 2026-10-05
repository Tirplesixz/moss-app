import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/analytics/event_log_repository.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/features/settings/data/settings_repository.dart';
import 'package:moss/features/tasks/data/block_repository.dart';
import 'package:moss/features/tasks/data/task_repository.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:moss/features/today/presentation/today_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/test_database.dart';

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

  test('TodayController loads empty DB and persists a task', () async {
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
    expect(controller.state.isLoading, isFalse);

    final now = DateTime.now().toUtc();
    final task = Task(
      id: 'persist-me',
      title: 'งานที่ต้องอยู่หลังเปิดใหม่',
      durationMin: 30,
      createdAt: now,
      updatedAt: now,
    );
    await controller.addManualTask(task);

    expect((await tasks.getTaskById(task.id))?.title, task.title);
    expect(controller.state.errorMessage, isNull);
    controller.dispose();
    await database.close();
  });
}
