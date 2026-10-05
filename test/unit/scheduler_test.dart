import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/scheduler/scheduler.dart';
import 'package:moss/features/settings/domain/app_settings.dart';
import 'package:moss/features/tasks/domain/block.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  late AppSettings defaultSettings;

  setUp(() {
    defaultSettings = AppSettings(
      id: 'test_settings',
      workdayStart: '09:00',
      workdayEnd: '18:00',
      bufferMin: 5,
      timezone: 'Asia/Bangkok',
      updatedAt: DateTime.utc(2026, 9, 30, 0, 0),
    );
  });

  group('Scheduler Spec 6.3 Required Unit Tests', () {
    test(
      '1. Empty day; single task lands at next 5-minute mark inside the workday',
      () {
        // 09:02 local time -> next 5-minute mark is 09:05 local
        final nowLocal = DateTime(2026, 9, 30, 9, 2);
        final nowUtc = nowLocal.toUtc();

        final task = Task(
          id: uuid.v4(),
          title: 'Task 1',
          durationMin: 30,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        );

        final result = Scheduler.schedule(
          tasks: [task],
          fixedBlocks: [],
          settings: defaultSettings,
          now: nowUtc,
        );

        expect(result.overflow, isEmpty);
        expect(result.blocks.length, 1);
        final block = result.blocks.first;
        expect(block.taskId, task.id);
        expect(block.startAt.toLocal(), DateTime(2026, 9, 30, 9, 5));
        expect(block.endAt.toLocal(), DateTime(2026, 9, 30, 9, 35));
      },
    );

    test('1b. Empty day before workday; task starts at workdayStart', () {
      // 07:45 local time -> before 09:00 workdayStart
      final nowLocal = DateTime(2026, 9, 30, 7, 45);
      final nowUtc = nowLocal.toUtc();

      final task = Task(
        id: uuid.v4(),
        title: 'Morning task',
        durationMin: 45,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );

      final result = Scheduler.schedule(
        tasks: [task],
        fixedBlocks: [],
        settings: defaultSettings,
        now: nowUtc,
      );

      expect(result.overflow, isEmpty);
      expect(
        result.blocks.first.startAt.toLocal(),
        DateTime(2026, 9, 30, 9, 0),
      );
      expect(result.blocks.first.endAt.toLocal(), DateTime(2026, 9, 30, 9, 45));
    });

    test('2. Two tasks with different deadlines are ordered by deadline', () {
      final nowLocal = DateTime(2026, 9, 30, 9, 0);
      final nowUtc = nowLocal.toUtc();

      // Task A: Later deadline (15:00)
      final taskA = Task(
        id: 'task_a',
        title: 'Task A (Later deadline)',
        durationMin: 60,
        deadlineAt: DateTime(2026, 9, 30, 15, 0).toUtc(),
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );

      // Task B: Earlier deadline (12:00)
      final taskB = Task(
        id: 'task_b',
        title: 'Task B (Earlier deadline)',
        durationMin: 60,
        deadlineAt: DateTime(2026, 9, 30, 12, 0).toUtc(),
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );

      // Pass taskA first in the list
      final result = Scheduler.schedule(
        tasks: [taskA, taskB],
        fixedBlocks: [],
        settings: defaultSettings,
        now: nowUtc,
      );

      expect(result.overflow, isEmpty);
      expect(result.blocks.length, 2);
      // Task B must be placed first because its deadline is earlier
      expect(result.blocks[0].taskId, taskB.id);
      expect(result.blocks[1].taskId, taskA.id);
      expect(result.blocks[0].startAt.toLocal(), DateTime(2026, 9, 30, 9, 0));
      expect(result.blocks[0].endAt.toLocal(), DateTime(2026, 9, 30, 10, 0));
      // With buffer 5 min, Task A starts at 10:05
      expect(result.blocks[1].startAt.toLocal(), DateTime(2026, 9, 30, 10, 5));
    });

    test('3. Task does not overlap a fixed block', () {
      final nowLocal = DateTime(2026, 9, 30, 9, 0);
      final nowUtc = nowLocal.toUtc();

      // Fixed block: Meeting from 09:00 to 10:30
      final meetingStart = DateTime(2026, 9, 30, 9, 0).toUtc();
      final meetingEnd = DateTime(2026, 9, 30, 10, 30).toUtc();
      final fixedMeeting = Block(
        id: 'fixed_meeting_1',
        kind: BlockKind.fixed,
        title: 'ประชุมลูกค้า',
        startAt: meetingStart,
        endAt: meetingEnd,
        locked: true,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );

      final task = Task(
        id: 'task_work',
        title: 'เขียนโค้ด',
        durationMin: 60,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );

      final result = Scheduler.schedule(
        tasks: [task],
        fixedBlocks: [fixedMeeting],
        settings: defaultSettings,
        now: nowUtc,
      );

      expect(result.overflow, isEmpty);
      expect(result.blocks.length, 1);
      final block = result.blocks.first;
      // Task must be scheduled after the meeting (10:30 + 5 min buffer = 10:35)
      expect(block.startAt.toLocal(), DateTime(2026, 9, 30, 10, 35));
      expect(block.endAt.toLocal(), DateTime(2026, 9, 30, 11, 35));
    });

    test(
      '4. Task that would straddle the end of the workday moves to the next day start',
      () {
        // Workday ends at 18:00. Now is 17:30. Task is 60 min -> would finish at 18:30 (straddles)
        final nowLocal = DateTime(2026, 9, 30, 17, 30);
        final nowUtc = nowLocal.toUtc();

        final task = Task(
          id: 'long_task',
          title: 'งานยาว 60 นาที',
          durationMin: 60,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        );

        final result = Scheduler.schedule(
          tasks: [task],
          fixedBlocks: [],
          settings: defaultSettings,
          now: nowUtc,
        );

        expect(result.overflow, isEmpty);
        expect(result.blocks.length, 1);
        final block = result.blocks.first;
        // Must move to next day (Oct 1) at 09:00
        expect(block.startAt.toLocal(), DateTime(2026, 10, 1, 9, 0));
        expect(block.endAt.toLocal(), DateTime(2026, 10, 1, 10, 0));
      },
    );

    test(
      '5. Deadline too tight -> task appears in overflow, not silently dropped',
      () {
        // Now is 11:30. Task is 60 min. Deadline is 12:00 (only 30 min available)
        final nowLocal = DateTime(2026, 9, 30, 11, 30);
        final nowUtc = nowLocal.toUtc();

        final task = Task(
          id: 'tight_task',
          title: 'งานเดดไลน์กระชั้นชิด',
          durationMin: 60,
          deadlineAt: DateTime(2026, 9, 30, 12, 0).toUtc(),
          createdAt: nowUtc,
          updatedAt: nowUtc,
        );

        final result = Scheduler.schedule(
          tasks: [task],
          fixedBlocks: [],
          settings: defaultSettings,
          now: nowUtc,
        );

        expect(result.blocks, isEmpty);
        expect(result.overflow.length, 1);
        expect(result.overflow.first.id, task.id);
      },
    );

    test('6. Locked block never moves', () {
      final nowLocal = DateTime(2026, 9, 30, 9, 0);
      final nowUtc = nowLocal.toUtc();

      // A locked task block from 11:00 to 12:00
      final lockedBlock = Block(
        id: 'locked_block_1',
        kind: BlockKind.task,
        title: 'งานที่ผู้ใช้ล็อคไว้',
        startAt: DateTime(2026, 9, 30, 11, 0).toUtc(),
        endAt: DateTime(2026, 9, 30, 12, 0).toUtc(),
        locked: true,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );

      // Two 60-min tasks
      final task1 = Task(
        id: 'task_1',
        title: 'Task 1',
        durationMin: 60,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );
      final task2 = Task(
        id: 'task_2',
        title: 'Task 2',
        durationMin: 60,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      );

      final result = Scheduler.schedule(
        tasks: [task1, task2],
        fixedBlocks: [lockedBlock],
        settings: defaultSettings,
        now: nowUtc,
      );

      expect(result.overflow, isEmpty);
      expect(result.blocks.length, 2);
      // task1 placed at 09:00 - 10:00
      expect(result.blocks[0].startAt.toLocal(), DateTime(2026, 9, 30, 9, 0));
      expect(result.blocks[0].endAt.toLocal(), DateTime(2026, 9, 30, 10, 0));
      // task2 cannot fit before 11:00 because 10:05 + 60 min = 11:05 > 11:00
      // So task2 is placed AFTER locked block at 12:05
      expect(result.blocks[1].startAt.toLocal(), DateTime(2026, 9, 30, 12, 5));
    });

    test(
      '7. Crossing midnight and timezone conversion do not corrupt times (UTC storage)',
      () {
        // 23:45 UTC = 06:45 local in Bangkok (+7)
        final nowUtc = DateTime.utc(2026, 9, 30, 23, 45);

        final task = Task(
          id: 'midnight_task',
          title: 'Midnight test',
          durationMin: 30,
          createdAt: nowUtc,
          updatedAt: nowUtc,
        );

        final result = Scheduler.schedule(
          tasks: [task],
          fixedBlocks: [],
          settings: defaultSettings,
          now: nowUtc,
        );

        expect(result.overflow, isEmpty);
        final scheduled = result.blocks.first;
        expect(scheduled.startAt.isUtc, isTrue);
        expect(scheduled.endAt.isUtc, isTrue);
        // In local Bangkok time, it lands at 09:00 on Oct 1
        expect(scheduled.startAt.toLocal().day, 1);
        expect(scheduled.startAt.toLocal().hour, 9);
        expect(scheduled.startAt.toLocal().minute, 0);
      },
    );

    test(
      '8. Determinism: run twice with the same input, results are equal',
      () {
        final nowUtc = DateTime.utc(2026, 9, 30, 3, 0); // 10:00 local

        final tasks = [
          Task(
            id: 'det_1',
            title: 'Det 1',
            durationMin: 30,
            priority: 3,
            createdAt: nowUtc,
            updatedAt: nowUtc,
          ),
          Task(
            id: 'det_2',
            title: 'Det 2',
            durationMin: 45,
            priority: 2,
            createdAt: nowUtc,
            updatedAt: nowUtc,
          ),
        ];

        final run1 = Scheduler.schedule(
          tasks: tasks,
          fixedBlocks: [],
          settings: defaultSettings,
          now: nowUtc,
        );

        final run2 = Scheduler.schedule(
          tasks: tasks,
          fixedBlocks: [],
          settings: defaultSettings,
          now: nowUtc,
        );

        expect(run1.blocks.length, run2.blocks.length);
        for (int i = 0; i < run1.blocks.length; i++) {
          expect(run1.blocks[i].taskId, run2.blocks[i].taskId);
          expect(run1.blocks[i].startAt, run2.blocks[i].startAt);
          expect(run1.blocks[i].endAt, run2.blocks[i].endAt);
        }
        expect(run1.overflow.length, run2.overflow.length);
      },
    );
  });
}
