import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/database/app_database.dart';
import 'package:moss/core/database/tables.dart';
import 'package:moss/core/notifications/notification_service.dart';
import 'package:moss/features/tasks/data/notif_repository.dart';
import 'package:moss/features/tasks/domain/block.dart';
import 'package:moss/features/tasks/domain/notif.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import 'package:moss/core/utils/time_utils.dart';

// Fake Notification Client for testing
class FakeNotificationClient implements INotificationClient {
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];
  bool requestPermissionCalled = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledIds.add(id);
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
  }) async {
    scheduledIds.add(id);
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
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  tz.initializeTimeZones();

  late Database db;
  late AppDatabase appDatabase;
  late NotifRepository notifRepo;
  late FakeNotificationClient fakeClient;
  late NotificationService notifService;

  const uuid = Uuid();

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(AppDatabaseTables.createNotifsTable);

    appDatabase = AppDatabase(customDb: db);
    notifRepo = NotifRepository(appDatabase);
    fakeClient = FakeNotificationClient();
    notifService = NotificationService(
      client: fakeClient,
      notifRepository: notifRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('NotificationService tests', () {
    test('generateOsNotifId produces deterministic positive integer', () {
      final id1 = NotificationService.generateOsNotifId(
        'block_123',
        NotifType.start,
      );
      final id2 = NotificationService.generateOsNotifId(
        'block_123',
        NotifType.start,
      );
      final id3 = NotificationService.generateOsNotifId(
        'block_123',
        NotifType.deadline,
      );

      expect(id1, isPositive);
      expect(id1, id2);
      expect(id1 != id3, isTrue);
    });

    test('requestPermission delegates to client', () async {
      final granted = await notifService.requestPermission();
      expect(granted, isTrue);
      expect(fakeClient.requestPermissionCalled, isTrue);
    });

    test(
      'cancelNotificationsForBlock cancels in plugin and removes from DB',
      () async {
        const blockId = 'block_test_cancel';
        final nowUtc = TimeUtils.nowUtc();

        await notifRepo.createNotif(
          Notif(
            id: uuid.v4(),
            blockId: blockId,
            type: NotifType.start,
            fireAt: nowUtc.add(const Duration(minutes: 30)),
            osNotifId: 12345,
            createdAt: nowUtc,
            updatedAt: nowUtc,
          ),
        );

        final before = await notifRepo.getNotifsForBlock(blockId);
        expect(before.length, 1);

        await notifService.cancelNotificationsForBlock(blockId);

        expect(fakeClient.cancelledIds, contains(12345));
        final after = await notifRepo.getNotifsForBlock(blockId);
        expect(after, isEmpty);
      },
    );

    test(
      'syncScheduleNotifications schedules start and deadline within 48h horizon',
      () async {
        final nowUtc = TimeUtils.nowUtc();
        final taskId = uuid.v4();
        final blockId = uuid.v4();

        final task = Task(
          id: taskId,
          title: 'ส่งงานลูกค้า',
          durationMin: 60,
          deadlineAt: nowUtc.add(const Duration(hours: 4)), // In 4 hours
          createdAt: nowUtc,
          updatedAt: nowUtc,
        );

        final block = Block(
          id: blockId,
          kind: BlockKind.task,
          taskId: taskId,
          title: task.title,
          startAt: nowUtc.add(const Duration(hours: 1)), // In 1 hour
          endAt: nowUtc.add(const Duration(hours: 2)),
          createdAt: nowUtc,
          updatedAt: nowUtc,
        );

        // Block beyond 48h horizon (e.g. 50 hours later)
        final farBlock = Block(
          id: uuid.v4(),
          kind: BlockKind.task,
          title: 'Far block',
          startAt: nowUtc.add(const Duration(hours: 50)),
          endAt: nowUtc.add(const Duration(hours: 51)),
          createdAt: nowUtc,
          updatedAt: nowUtc,
        );

        await notifService.syncScheduleNotifications(
          blocks: [block, farBlock],
          tasks: [task],
          now: nowUtc,
          deadlineWarningMinutes: 60,
        );

        // Should have scheduled:
        // 1. Block start notification for `block`
        // 2. Deadline notification for `block` (fireAt = now + 4h - 60m = now + 3h)
        // `farBlock` is > 48h so it should not be scheduled.
        final upcomingNotifs = await notifRepo.getUpcomingNotifs(
          nowUtc.add(const Duration(hours: 48)),
        );
        expect(upcomingNotifs.length, 2);

        final startNotif = upcomingNotifs.firstWhere(
          (n) => n.type == NotifType.start,
        );
        expect(startNotif.blockId, blockId);
        expect(startNotif.fireAt, block.startAt);

        final deadlineNotif = upcomingNotifs.firstWhere(
          (n) => n.type == NotifType.deadline,
        );
        expect(deadlineNotif.blockId, blockId);
        expect(
          deadlineNotif.fireAt,
          task.deadlineAt!.subtract(const Duration(minutes: 60)),
        );
        expect(fakeClient.scheduledIds.length, 2);
      },
    );
  });
}
