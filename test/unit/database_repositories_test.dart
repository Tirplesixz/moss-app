import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/database/app_database.dart';
import 'package:moss/core/database/tables.dart';
import 'package:moss/core/utils/time_utils.dart';
import 'package:moss/features/settings/data/settings_repository.dart';
import 'package:moss/features/settings/domain/app_settings.dart';
import 'package:moss/features/tasks/data/block_repository.dart';
import 'package:moss/features/tasks/data/notif_repository.dart';
import 'package:moss/features/tasks/data/task_repository.dart';
import 'package:moss/features/tasks/domain/block.dart';
import 'package:moss/features/tasks/domain/notif.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  // Setup FFI for desktop unit testing of SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AppDatabase appDatabase;
  late TaskRepository taskRepo;
  late BlockRepository blockRepo;
  late SettingsRepository settingsRepo;
  late NotifRepository notifRepo;

  const uuid = Uuid();

  setUp(() async {
    // In-memory database for isolated, fast unit tests
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Run table creation and default seeding as in AppDatabase
    await db.execute(AppDatabaseTables.createTasksTable);
    await db.execute(AppDatabaseTables.createBlocksTable);
    await db.execute(AppDatabaseTables.createSettingsTable);
    await db.execute(AppDatabaseTables.createNotifsTable);

    final defaultSettings = AppSettings.createDefault();
    await db.insert(AppDatabaseTables.tableSettings, {
      'id': defaultSettings.id,
      'workday_start': defaultSettings.workdayStart,
      'workday_end': defaultSettings.workdayEnd,
      'buffer_min': defaultSettings.bufferMin,
      'timezone': defaultSettings.timezone,
      'updated_at': defaultSettings.updatedAt.toUtc().toIso8601String(),
      'deleted_at': null,
    });

    appDatabase = AppDatabase(customDb: db);
    taskRepo = TaskRepository(appDatabase);
    blockRepo = BlockRepository(appDatabase);
    settingsRepo = SettingsRepository(appDatabase);
    notifRepo = NotifRepository(appDatabase);
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskRepository tests', () {
    test('create, fetch by id, and soft delete task', () async {
      final now = TimeUtils.nowUtc();
      final task = Task(
        id: uuid.v4(),
        title: 'ส่งรายงานสรุปยอด',
        durationMin: 45,
        deadlineAt: now.add(const Duration(hours: 3)),
        priority: 2,
        projectName: 'เว็บไซต์ลูกค้า',
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
      );

      await taskRepo.createTask(task);
      final fetched = await taskRepo.getTaskById(task.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'ส่งรายงานสรุปยอด');
      expect(fetched.durationMin, 45);
      expect(fetched.projectName, 'เว็บไซต์ลูกค้า');
      expect(fetched.isDeleted, isFalse);

      // Soft delete
      await taskRepo.softDeleteTask(task.id);
      final afterDelete = await taskRepo.getTaskById(task.id);
      expect(
        afterDelete,
        isNull,
      ); // Soft deleted items are excluded from active fetch
    });

    test(
      'getActiveTodoTasks orders by deadline ASC, priority DESC, createdAt ASC',
      () async {
        final now = TimeUtils.nowUtc();

        final t1 = Task(
          id: uuid.v4(),
          title: 'Task 1: Late deadline',
          durationMin: 30,
          deadlineAt: now.add(const Duration(hours: 5)),
          priority: 2,
          createdAt: now,
          updatedAt: now,
        );

        final t2 = Task(
          id: uuid.v4(),
          title: 'Task 2: Earlier deadline',
          durationMin: 30,
          deadlineAt: now.add(const Duration(hours: 2)),
          priority: 2,
          createdAt: now,
          updatedAt: now,
        );

        final t3 = Task(
          id: uuid.v4(),
          title: 'Task 3: No deadline, high priority',
          durationMin: 30,
          deadlineAt: null,
          priority: 3,
          createdAt: now,
          updatedAt: now,
        );

        await taskRepo.createTask(t1);
        await taskRepo.createTask(t2);
        await taskRepo.createTask(t3);

        final tasks = await taskRepo.getActiveTodoTasks();
        expect(tasks.length, 3);
        // t2 has earliest deadline -> first
        expect(tasks[0].id, t2.id);
        // t1 has next deadline -> second
        expect(tasks[1].id, t1.id);
        // t3 has no deadline -> last
        expect(tasks[2].id, t3.id);
      },
    );
  });

  group('BlockRepository tests', () {
    test('queries and soft deletes every active block for a task', () async {
      final now = TimeUtils.nowUtc();
      final taskId = uuid.v4();
      final task = Task(
        id: taskId,
        title: 'งานหลายช่วง',
        durationMin: 60,
        createdAt: now,
        updatedAt: now,
      );
      await taskRepo.createTask(task);

      for (var index = 0; index < 2; index++) {
        await blockRepo.createBlock(
          Block(
            id: uuid.v4(),
            kind: BlockKind.task,
            taskId: taskId,
            startAt: now.add(Duration(hours: index)),
            endAt: now.add(Duration(hours: index, minutes: 30)),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      expect(await blockRepo.getActiveBlocksForTask(taskId), hasLength(2));
      await blockRepo.softDeleteBlocksForTask(taskId);
      expect(await blockRepo.getActiveBlocksForTask(taskId), isEmpty);
    });

    test('create, getBlocksInRange, and replaceMovableTaskBlocks', () async {
      final now = TimeUtils.nowUtc();
      final start = now;
      final end = now.add(const Duration(minutes: 60));

      final fixedBlock = Block(
        id: uuid.v4(),
        kind: BlockKind.fixed,
        title: 'ประชุมทีม',
        startAt: start,
        endAt: end,
        locked: true,
        createdAt: now,
        updatedAt: now,
      );

      await blockRepo.createBlock(fixedBlock);

      final fixedList = await blockRepo.getActiveFixedBlocks();
      expect(fixedList.length, 1);
      expect(fixedList.first.title, 'ประชุมทีม');
      expect(fixedList.first.locked, isTrue);

      // Movable task block
      final taskBlock = Block(
        id: uuid.v4(),
        kind: BlockKind.task,
        title: 'เขียนโค้ด',
        startAt: end.add(const Duration(minutes: 10)),
        endAt: end.add(const Duration(minutes: 70)),
        locked: false,
        createdAt: now,
        updatedAt: now,
      );

      await blockRepo.createBlock(taskBlock);

      // Check range query
      final inRange = await blockRepo.getBlocksInRange(
        now.subtract(const Duration(minutes: 10)),
        end.add(const Duration(hours: 2)),
      );
      expect(inRange.length, 2);

      // Replace movable task blocks
      final replacementBlock = Block(
        id: uuid.v4(),
        kind: BlockKind.task,
        title: 'เขียนโค้ดจัดตารางใหม่',
        startAt: end.add(const Duration(minutes: 15)),
        endAt: end.add(const Duration(minutes: 75)),
        locked: false,
        createdAt: now,
        updatedAt: now,
      );

      await blockRepo.replaceMovableTaskBlocks([replacementBlock], end);

      final updatedBlocks = await blockRepo.getBlocksInRange(
        now.subtract(const Duration(minutes: 10)),
        end.add(const Duration(hours: 2)),
      );
      // Fixed block still exists, old movable task block soft-deleted, new one present
      expect(updatedBlocks.length, 2);
      expect(updatedBlocks.any((b) => b.id == fixedBlock.id), isTrue);
      expect(updatedBlocks.any((b) => b.id == replacementBlock.id), isTrue);
      expect(updatedBlocks.any((b) => b.id == taskBlock.id), isFalse);
    });
  });

  group('SettingsRepository tests', () {
    test(
      'getSettings returns default seeded settings and updateSettings persists changes',
      () async {
        final settings = await settingsRepo.getSettings();
        expect(settings.workdayStart, '09:00');
        expect(settings.workdayEnd, '18:00');
        expect(settings.bufferMin, 5);
        expect(settings.appearanceMode, 'system');
        expect(settings.saveCompletedToCalendar, isFalse);

        final updated = settings.copyWith(
          workdayStart: '08:30',
          bufferMin: 10,
          appearanceMode: 'dark',
          saveCompletedToCalendar: true,
        );
        await settingsRepo.updateSettings(updated);

        final reFetched = await settingsRepo.getSettings();
        expect(reFetched.workdayStart, '08:30');
        expect(reFetched.bufferMin, 10);
        expect(reFetched.appearanceMode, 'dark');
        expect(reFetched.saveCompletedToCalendar, isTrue);
      },
    );
  });

  group('NotifRepository tests', () {
    test('create, getUpcomingNotifs, and deleteNotifsForBlock', () async {
      final now = TimeUtils.nowUtc();
      final blockId = uuid.v4();

      final notif = Notif(
        id: uuid.v4(),
        blockId: blockId,
        type: NotifType.start,
        fireAt: now.add(const Duration(minutes: 15)),
        osNotifId: 101,
        createdAt: now,
        updatedAt: now,
      );

      await notifRepo.createNotif(notif);

      final upcoming = await notifRepo.getUpcomingNotifs(
        now.add(const Duration(hours: 1)),
      );
      expect(upcoming.length, 1);
      expect(upcoming.first.osNotifId, 101);

      await notifRepo.deleteNotifsForBlock(blockId);
      final remaining = await notifRepo.getUpcomingNotifs(
        now.add(const Duration(hours: 1)),
      );
      expect(remaining.isEmpty, isTrue);
    });
  });
}
