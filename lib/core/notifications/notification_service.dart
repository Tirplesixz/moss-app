import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../utils/thai_date_formatter.dart';
import '../utils/time_utils.dart';
import '../../features/tasks/data/notif_repository.dart';
import '../../features/tasks/domain/block.dart';
import '../../features/tasks/domain/notif.dart';
import '../../features/tasks/domain/task.dart';

/// Interface for notification client to support both platform implementation and unit test mocks.
abstract class INotificationClient {
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  });

  Future<void> cancel({required int id, String? tag});

  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  });

  Future<bool?> requestAndroidPermission();
  Future<bool?> requestIosPermission();
}

/// Default implementation wrapping FlutterLocalNotificationsPlugin.
class DefaultNotificationClient implements INotificationClient {
  final FlutterLocalNotificationsPlugin _plugin;

  DefaultNotificationClient([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) {
    if (kIsWeb) return Future.value(true);
    return _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  @override
  Future<void> cancel({required int id, String? tag}) {
    if (kIsWeb) return Future.value();
    return _plugin.cancel(id: id, tag: tag);
  }

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
  }) {
    if (kIsWeb) return Future.value();
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: androidScheduleMode,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    if (kIsWeb) return true;
    return await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<bool?> requestIosPermission() async {
    if (kIsWeb) return true;
    return await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}

/// Notification service for Moss app managing local notifications according to PLAN.md Section 9.
class NotificationService {
  final INotificationClient _client;
  final NotifRepository? _notifRepository;
  static const _uuid = Uuid();

  bool _isInitialized = false;

  NotificationService({
    INotificationClient? client,
    NotifRepository? notifRepository,
  }) : _client = client ?? DefaultNotificationClient(),
       _notifRepository = notifRepository;

  static const String channelId = 'moss_task_channel';
  static const String channelName = 'การแจ้งเตือนงาน Moss';
  static const String channelDescription =
      'แจ้งเตือนเมื่อถึงเวลาเริ่มงานและใกล้กำหนดส่ง';

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _client.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  /// Asks for notification permission after the first task is added (PLAN.md Section 9).
  Future<bool> requestPermission() async {
    try {
      final androidGranted = await _client.requestAndroidPermission();
      if (androidGranted != null) return androidGranted;

      final iosGranted = await _client.requestIosPermission();
      if (iosGranted != null) return iosGranted;

      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Cancels all notifications associated with a specific block.
  Future<void> cancelNotificationsForBlock(String blockId) async {
    if (_notifRepository != null) {
      final existingNotifs = await _notifRepository.getNotifsForBlock(blockId);
      for (final n in existingNotifs) {
        await _client.cancel(id: n.osNotifId);
      }
      await _notifRepository.deleteNotifsForBlock(blockId);
    }
  }

  /// Generates a deterministic positive 31-bit integer ID for OS notification.
  static int generateOsNotifId(String blockId, NotifType type) {
    final combined = '${blockId}_${type.value}';
    return combined.hashCode.abs() % 2147483647;
  }

  /// Synchronizes notifications for scheduled blocks within the 48-hour horizon.
  Future<void> syncScheduleNotifications({
    required List<Block> blocks,
    required List<Task> tasks,
    DateTime? now,
    int deadlineWarningMinutes = 60,
  }) async {
    final currentUtc = (now ?? TimeUtils.nowUtc()).toUtc();
    final horizonUtc = currentUtc.add(const Duration(hours: 48));

    final taskMap = {for (final t in tasks) t.id: t};

    for (final block in blocks) {
      if (block.isDeleted) continue;

      // Cancel existing notifications for this block to avoid duplicates
      await cancelNotificationsForBlock(block.id);

      final task = block.taskId != null ? taskMap[block.taskId] : null;
      final title = block.title ?? task?.title ?? 'งานของคุณ';

      // 1. Block Start notification (if in future and <= 48 hours)
      if (block.startAt.isAfter(currentUtc) &&
          block.startAt.isBefore(horizonUtc)) {
        final osId = generateOsNotifId(block.id, NotifType.start);
        final fireAtLocal = block.startAt.toLocal();
        final tzDateTime = tz.TZDateTime.from(fireAtLocal, tz.local);

        const androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        );
        const iosDetails = DarwinNotificationDetails();
        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final durationStr = '${block.durationMin} นาที';
        try {
          await _client.zonedSchedule(
            id: osId,
            title: 'ถึงเวลา: $title',
            body: 'เริ่มทำได้เลย (ใช้เวลา $durationStr)',
            scheduledDate: tzDateTime,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: block.id,
          );

          if (_notifRepository != null) {
            await _notifRepository.createNotif(
              Notif(
                id: _uuid.v4(),
                blockId: block.id,
                type: NotifType.start,
                fireAt: block.startAt,
                osNotifId: osId,
                createdAt: currentUtc,
                updatedAt: currentUtc,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error scheduling block start notification: $e');
        }
      }

      // 2. Deadline notification (if task has deadlineAt)
      if (task?.deadlineAt != null) {
        final deadlineAt = task!.deadlineAt!.toUtc();
        final fireAtUtc = deadlineAt.subtract(
          Duration(minutes: deadlineWarningMinutes),
        );

        if (fireAtUtc.isAfter(currentUtc) && fireAtUtc.isBefore(horizonUtc)) {
          final osId = generateOsNotifId(block.id, NotifType.deadline);
          final fireAtLocal = fireAtUtc.toLocal();
          final tzDateTime = tz.TZDateTime.from(fireAtLocal, tz.local);

          const androidDetails = AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          );
          const iosDetails = DarwinNotificationDetails();
          const details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          final timeText = ThaiDateFormatter.formatTime(deadlineAt.toLocal());
          try {
            await _client.zonedSchedule(
              id: osId,
              title: 'ใกล้ถึงกำหนดส่ง: $title',
              body:
                  'เหลืออีก $deadlineWarningMinutes นาที จะถึงกำหนดส่ง ($timeText)',
              scheduledDate: tzDateTime,
              notificationDetails: details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: block.id,
            );

            if (_notifRepository != null) {
              await _notifRepository.createNotif(
                Notif(
                  id: _uuid.v4(),
                  blockId: block.id,
                  type: NotifType.deadline,
                  fireAt: fireAtUtc,
                  osNotifId: osId,
                  createdAt: currentUtc,
                  updatedAt: currentUtc,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error scheduling deadline notification: $e');
          }
        }
      }
    }
  }
}
