import 'package:flutter_test/flutter_test.dart';
import 'package:moss/features/lockscreen/data/lockscreen_repository.dart';
import 'package:moss/features/lockscreen/domain/lockscreen_config.dart';
import 'package:moss/features/lockscreen/presentation/lockscreen_view_model.dart';
import 'package:moss/features/tasks/data/block_repository.dart';
import 'package:moss/features/tasks/data/task_repository.dart';

import '../helpers/test_database.dart';

void main() {
  group('LockScreen Advanced Features Tests (LockDay Parity)', () {
    test('LockScreenConfig roundtrip with year_progress and paper_style', () {
      final initial = LockScreenConfig.initial();
      expect(initial.showYearProgress, isFalse);
      expect(initial.paperStyle, 'plain');
      expect(initial.moduleOrder.contains('year_progress'), isTrue);

      final custom = initial.copyWith(
        showYearProgress: true,
        paperStyle: 'lined',
      );
      expect(custom.showYearProgress, isTrue);
      expect(custom.paperStyle, 'lined');
    });

    test('LockScreenRepository saves and loads year_progress and paper_style', () async {
      final appDb = await createTestDatabase();
      final repo = LockScreenRepository(appDb);

      final loaded = await repo.loadActive();
      expect(loaded.showYearProgress, isFalse);
      expect(loaded.paperStyle, 'plain');

      final updated = loaded.copyWith(
        showYearProgress: true,
        paperStyle: 'grid',
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.save(updated);

      final reloaded = await repo.loadActive();
      expect(reloaded.showYearProgress, isTrue);
      expect(reloaded.paperStyle, 'grid');
    });

    test('LockScreenViewModel updates draft config for year progress and paper style', () async {
      final appDb = await createTestDatabase();
      final repo = LockScreenRepository(appDb);
      final taskRepo = TaskRepository(appDb);
      final blockRepo = BlockRepository(appDb);

      final vm = LockScreenViewModel(
        repository: repo,
        taskRepository: taskRepo,
        blockRepository: blockRepo,
      );

      await vm.load();
      expect(vm.config.showYearProgress, isFalse);

      vm.setShowYearProgress(true);
      expect(vm.config.showYearProgress, isTrue);
      expect(vm.hasChanges, isTrue);

      vm.setPaperStyle('tape');
      expect(vm.config.paperStyle, 'tape');

      await vm.save();
      expect(vm.hasChanges, isFalse);

      final reloaded = await repo.loadActive();
      expect(reloaded.showYearProgress, isTrue);
      expect(reloaded.paperStyle, 'tape');
    });
  });
}
