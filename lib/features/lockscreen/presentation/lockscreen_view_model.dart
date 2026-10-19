import 'package:flutter/foundation.dart';

import '../../tasks/data/task_repository.dart';
import '../../tasks/data/block_repository.dart';
import '../../tasks/domain/block.dart';
import '../../tasks/domain/task.dart';
import '../data/lockscreen_repository.dart';
import '../domain/lockscreen_config.dart';

class LockScreenViewModel extends ChangeNotifier {
  LockScreenViewModel({
    required LockScreenRepository repository,
    required TaskRepository taskRepository,
    required BlockRepository blockRepository,
  }) : _repository = repository,
       _taskRepository = taskRepository,
       _blockRepository = blockRepository;

  final LockScreenRepository _repository;
  final TaskRepository _taskRepository;
  final BlockRepository _blockRepository;

  LockScreenConfig _saved = LockScreenConfig.initial();
  LockScreenConfig _draft = LockScreenConfig.initial();
  List<Task> _tasks = const [];
  List<Block> _blocks = const [];
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  LockScreenConfig get config => _draft;
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Block> get blocks => List.unmodifiable(_blocks);
  bool get loading => _loading;
  bool get saving => _saving;
  bool get hasChanges => _draft != _saved;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - DateTime.monday));
      final results = await Future.wait([
        _repository.loadActive(),
        _taskRepository.getActiveTodoTasks(),
        _blockRepository.getBlocksInRange(
          weekStart.toUtc(),
          weekStart.add(const Duration(days: 7)).toUtc(),
        ),
      ]);
      _saved = results[0] as LockScreenConfig;
      _draft = _saved;
      _tasks = (results[1] as List<Task>).toList(growable: false);
      _blocks = (results[2] as List<Block>).toList(growable: false);
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectPreset(LockScreenPreset preset) {
    final selected = preset.toConfig();
    _draft = _draft.copyWith(
      templateId: selected.templateId,
      gradientStart: selected.gradientStart,
      gradientEnd: selected.gradientEnd,
      showClock: selected.showClock,
      showProgress: selected.showProgress,
      showTasks: selected.showTasks,
      showCalendar: selected.showCalendar,
    );
    notifyListeners();
  }

  void setShowClock(bool value) => _update(_draft.copyWith(showClock: value));
  void setShowProgress(bool value) =>
      _update(_draft.copyWith(showProgress: value));
  void setShowTasks(bool value) => _update(_draft.copyWith(showTasks: value));
  void setShowCalendar(bool value) =>
      _update(_draft.copyWith(showCalendar: value));
  void setAutoUpdate(bool value) => _update(_draft.copyWith(autoUpdate: value));
  void setTaskLimit(int value) =>
      _update(_draft.copyWith(taskLimit: value.clamp(1, 6)));
  void setVerticalOffset(double value) =>
      _update(_draft.copyWith(verticalOffset: value.clamp(0.0, 300.0)));
  void setShowCountdown(bool value) =>
      _update(_draft.copyWith(showCountdown: value));
  void setCountdownTitle(String value) =>
      _update(_draft.copyWith(countdownTitle: value));
  void setCountdownDate(String? value) =>
      _update(_draft.copyWith(countdownDate: value));
  void setShowPinnedNote(bool value) =>
      _update(_draft.copyWith(showPinnedNote: value));
  void setPinnedNoteText(String value) =>
      _update(_draft.copyWith(pinnedNoteText: value));
  void setDimPastEvents(bool value) =>
      _update(_draft.copyWith(dimPastEvents: value));
  void setShowYearProgress(bool value) =>
      _update(_draft.copyWith(showYearProgress: value));
  void setPaperStyle(String value) =>
      _update(_draft.copyWith(paperStyle: value));
  void setColors(int start, int end) => _update(
    _draft.copyWith(
      templateId: 'custom',
      gradientStart: start,
      gradientEnd: end,
    ),
  );

  void moveModule(int oldIndex, int newIndex) {
    final order = [..._draft.moduleOrder];
    if (newIndex > oldIndex) newIndex--;
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    _update(_draft.copyWith(moduleOrder: order));
  }

  void moveModuleBy(String id, int delta) {
    final oldIndex = _draft.moduleOrder.indexOf(id);
    if (oldIndex < 0) return;
    final newIndex = (oldIndex + delta).clamp(0, _draft.moduleOrder.length - 1);
    if (newIndex == oldIndex) return;
    final order = [..._draft.moduleOrder];
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    _update(_draft.copyWith(moduleOrder: order));
  }

  void reset() => _update(LockScreenConfig.initial());

  void _update(LockScreenConfig value) {
    _draft = value;
    notifyListeners();
  }

  Future<void> save({bool rendered = false}) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now().toUtc();
      _draft = _draft.copyWith(
        updatedAt: now,
        lastRenderedAt: rendered ? () => now : null,
      );
      await _repository.save(_draft);
      _saved = _draft;
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
