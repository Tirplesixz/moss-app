import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/calendar/data/calendar_task_sync_service.dart';
import 'package:moss/features/tasks/data/block_repository.dart';
import 'package:moss/features/tasks/data/task_repository.dart';
import 'package:moss/features/tasks/domain/block.dart';
import 'package:moss/features/tasks/domain/task.dart';

import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.moss.moss/calendar');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('creates, updates, and removes one calendar event for a task', () async {
    final database = await createTestDatabase();
    final tasks = TaskRepository(database);
    final blocks = BlockRepository(database);
    final sync = CalendarTaskSyncService(
      taskRepository: tasks,
      blockRepository: blocks,
    );
    final now = DateTime.utc(2026, 10, 18);
    final task = Task(
      id: 'task-21',
      title: 'ส่งรายงานวันที่ 21',
      durationMin: 60,
      deadlineAt: DateTime.utc(2026, 10, 21, 11),
      createdAt: now,
      updatedAt: now,
    );
    await tasks.createTask(task);
    await blocks.createBlock(
      Block(
        id: 'block-21',
        kind: BlockKind.task,
        taskId: task.id,
        startAt: DateTime.utc(2026, 10, 21, 9),
        endAt: DateTime.utc(2026, 10, 21, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'upsertTaskEvent') return 'event-21';
          if (call.method == 'deleteEvent') return true;
          return null;
        });

    expect(await sync.syncTask(task), isTrue);
    var stored = await tasks.getTaskById(task.id);
    expect(stored?.calendarEventId, 'event-21');
    expect(calls.single.method, 'upsertTaskEvent');
    expect(
      (calls.single.arguments as Map)['start'],
      DateTime.utc(2026, 10, 21, 9).millisecondsSinceEpoch,
    );

    await tasks.updateTask(task.copyWith(title: 'ส่งรายงานฉบับแก้ไข'));
    expect(await sync.syncTask(task), isTrue);
    expect((calls[1].arguments as Map)['eventId'], 'event-21');

    stored = await tasks.getTaskById(task.id);
    expect(await sync.removeTask(stored!), isTrue);
    expect(calls.last.method, 'deleteEvent');
    expect((await tasks.getTaskById(task.id))?.calendarEventId, isNull);
  });
}
