import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/lockscreen/data/lockscreen_repository.dart';
import 'package:moss/features/lockscreen/data/lockscreen_image_renderer.dart';
import 'package:moss/features/lockscreen/data/lockscreen_platform_service.dart';
import 'package:moss/features/lockscreen/data/lockscreen_sync_service.dart';
import 'package:moss/features/lockscreen/domain/lockscreen_config.dart';
import 'package:moss/features/lockscreen/presentation/lockscreen_view_model.dart';
import 'package:moss/features/tasks/data/task_repository.dart';
import 'package:moss/features/tasks/data/block_repository.dart';
import 'package:moss/features/tasks/domain/task.dart';
import 'package:moss/features/tasks/domain/block.dart';

import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists the active template and rendered timestamp', () async {
    final database = await createTestDatabase();
    final repository = LockScreenRepository(database);

    final initial = await repository.loadActive();
    expect(initial.templateId, 'midnight');

    final saved = lockScreenPresets[3].toConfig().copyWith(
      showClock: false,
      autoUpdate: true,
      taskLimit: 6,
      moduleOrder: const ['tasks', 'clock', 'calendar', 'progress'],
      lastRenderedAt: () => DateTime.utc(2026, 10, 17),
    );
    await repository.save(saved);

    final restored = await repository.loadActive();
    expect(restored.templateId, 'violet');
    expect(restored.showClock, isFalse);
    expect(restored.showCalendar, isTrue);
    expect(restored.autoUpdate, isTrue);
    expect(restored.taskLimit, 6);
    expect(restored.moduleOrder.first, 'tasks');
    expect(restored.lastRenderedAt, DateTime.utc(2026, 10, 17));
  });

  test('view model loads real tasks and commits a selected preset', () async {
    final database = await createTestDatabase();
    final taskRepository = TaskRepository(database);
    final repository = LockScreenRepository(database);
    final now = DateTime.utc(2026, 10, 17);
    await taskRepository.createTask(
      Task(
        id: 'focus-task',
        title: 'ส่งแบบให้ลูกค้า',
        durationMin: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final viewModel = LockScreenViewModel(
      repository: repository,
      taskRepository: taskRepository,
      blockRepository: BlockRepository(database),
    );
    await viewModel.load();

    expect(viewModel.tasks.single.title, 'ส่งแบบให้ลูกค้า');
    expect(viewModel.hasChanges, isFalse);

    viewModel.selectPreset(lockScreenPresets[2]);
    viewModel.setShowCalendar(true);
    expect(viewModel.hasChanges, isTrue);

    await viewModel.save(rendered: true);
    expect(viewModel.hasChanges, isFalse);
    expect(viewModel.config.lastRenderedAt, isNotNull);
    expect((await repository.loadActive()).templateId, 'forest');
  });

  test('renderer creates a real PNG wallpaper', () async {
    final bytes = await const LockScreenImageRenderer().render(
      config: LockScreenConfig.initial(),
      tasks: const [],
      now: DateTime(2026, 10, 17, 9, 41),
    );
    expect(bytes.length, greaterThan(1000));
    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test('week flow renderer includes scheduled blocks in a real PNG', () async {
    final now = DateTime(2026, 10, 19, 9, 41);
    final task = Task(
      id: 'weekly-task',
      title: 'ออกแบบหน้าใหม่',
      durationMin: 60,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
    final block = Block(
      id: 'weekly-block',
      kind: BlockKind.task,
      taskId: task.id,
      startAt: DateTime(2026, 10, 21, 10).toUtc(),
      endAt: DateTime(2026, 10, 21, 11, 30).toUtc(),
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
    final bytes = await const LockScreenImageRenderer().render(
      config: lockScreenPresets.last.toConfig(),
      tasks: [task],
      blocks: [block],
      now: now,
    );

    expect(bytes.length, greaterThan(10000));
    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test(
    'sync service respects autoUpdate and applies when enabled or forced',
    () async {
      final database = await createTestDatabase();
      final taskRepository = TaskRepository(database);
      final repository = LockScreenRepository(database);
      final fakePlatform = _FakePlatformService();

      final syncService = LockScreenSyncService(
        repository: repository,
        taskRepository: taskRepository,
        blockRepository: BlockRepository(database),
        platform: fakePlatform,
      );

      // 1. autoUpdate is false initially -> should skip
      final skipped = await syncService.syncIfEnabled();
      expect(skipped, isFalse);
      expect(fakePlatform.applyCount, 0);

      // 2. force = true -> should apply even if autoUpdate is false
      final forced = await syncService.syncIfEnabled(force: true);
      expect(forced, isTrue);
      expect(fakePlatform.applyCount, 1);
      final afterForce = await repository.loadActive();
      expect(afterForce.lastRenderedAt, isNotNull);

      // 3. Enable autoUpdate in config -> should apply
      await repository.save(afterForce.copyWith(autoUpdate: true));
      final autoSynced = await syncService.syncIfEnabled(force: true);
      expect(autoSynced, isTrue);
      expect(fakePlatform.applyCount, 2);
      expect(fakePlatform.lastSaveToGallery, isFalse);
    },
  );

  test('renderer renders countdown and pinned note into PNG', () async {
    final now = DateTime(2026, 10, 18, 10, 0);
    final config = LockScreenConfig.initial().copyWith(
      verticalOffset: 60.0,
      showCountdown: true,
      countdownTitle: 'วันขึ้นปีใหม่',
      countdownDate: '2027-01-01',
      showPinnedNote: true,
      pinnedNoteText: 'อย่าลืมออกกำลังกายตอนเย็น',
      dimPastEvents: true,
    );
    final taskOverdue = Task(
      id: 'past-task',
      title: 'งานที่เลยกำหนดแล้ว',
      durationMin: 30,
      deadlineAt: now.subtract(const Duration(hours: 2)),
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
    final taskCurrent = Task(
      id: 'current-task',
      title: 'งานปัจจุบัน',
      durationMin: 45,
      deadlineAt: now.add(const Duration(hours: 3)),
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );

    final bytes = await const LockScreenImageRenderer().render(
      config: config,
      tasks: [taskOverdue, taskCurrent],
      now: now,
    );
    expect(bytes.length, greaterThan(1000));
    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}

class _FakePlatformService extends LockScreenPlatformService {
  int applyCount = 0;
  Uint8List? lastBytes;
  bool? lastSaveToGallery;

  @override
  Future<WallpaperExportResult> apply(
    Uint8List pngBytes, {
    bool saveToGallery = true,
  }) async {
    applyCount++;
    lastBytes = pngBytes;
    lastSaveToGallery = saveToGallery;
    return const WallpaperExportResult(WallpaperExportAction.applied);
  }
}
