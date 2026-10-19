import 'package:flutter/foundation.dart';

import '../../tasks/data/task_repository.dart';
import '../../tasks/data/block_repository.dart';
import 'lockscreen_image_renderer.dart';
import 'lockscreen_platform_service.dart';
import 'lockscreen_repository.dart';

class LockScreenSyncService {
  LockScreenSyncService({
    required LockScreenRepository repository,
    required TaskRepository taskRepository,
    required BlockRepository blockRepository,
    LockScreenImageRenderer renderer = const LockScreenImageRenderer(),
    LockScreenPlatformService platform = const LockScreenPlatformService(),
  }) : _repository = repository,
       _taskRepository = taskRepository,
       _blockRepository = blockRepository,
       _renderer = renderer,
       _platform = platform;

  final LockScreenRepository _repository;
  final TaskRepository _taskRepository;
  final BlockRepository _blockRepository;
  final LockScreenImageRenderer _renderer;
  final LockScreenPlatformService _platform;
  bool _syncing = false;
  bool _pendingSync = false;

  Future<bool> syncIfEnabled({bool force = false}) async {
    if (kIsWeb) return false;
    if (_syncing) {
      _pendingSync = true;
      return false;
    }
    _syncing = true;
    bool anySuccess = false;
    try {
      do {
        _pendingSync = false;
        final config = await _repository.loadActive();
        if (!force && !config.autoUpdate) return anySuccess;
        if (defaultTargetPlatform != TargetPlatform.android && !force) {
          return anySuccess;
        }

        final tasks = await _taskRepository.getActiveTodoTasks();
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - DateTime.monday));
        final blocks = await _blockRepository.getBlocksInRange(
          weekStart.toUtc(),
          weekStart.add(const Duration(days: 7)).toUtc(),
        );
        final bytes = await _renderer.render(
          config: config,
          tasks: tasks,
          blocks: blocks,
        );
        // Background refreshes should replace the wallpaper without filling
        // the user's photo library with a new copy on every task change.
        await _platform.apply(bytes, saveToGallery: false);
        final renderedAt = DateTime.now().toUtc();
        await _repository.save(
          config.copyWith(
            updatedAt: renderedAt,
            lastRenderedAt: () => renderedAt,
          ),
        );
        anySuccess = true;
      } while (_pendingSync);
      return anySuccess;
    } catch (error, stackTrace) {
      debugPrint('Lock Screen auto-update skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
      return anySuccess;
    } finally {
      _syncing = false;
    }
  }
}
