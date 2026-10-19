import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../../features/tasks/data/task_repository.dart';
import '../../features/tasks/data/block_repository.dart';
import '../../features/tasks/data/notif_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../analytics/event_log_repository.dart';
import '../../features/lockscreen/data/lockscreen_repository.dart';
import '../../features/lockscreen/presentation/lockscreen_view_model.dart';
import '../../features/lockscreen/data/lockscreen_sync_service.dart';
import '../../features/notes/data/note_repository.dart';
import '../../features/notes/presentation/notes_view_model.dart';
import '../../features/calendar/data/device_calendar_service.dart';
import '../../features/calendar/data/calendar_task_sync_service.dart';
import '../../features/calendar/presentation/device_calendar_view_model.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskRepository(db);
});

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BlockRepository(db);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsRepository(db);
});

final notifRepositoryProvider = Provider<NotifRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NotifRepository(db);
});

final eventLogRepositoryProvider = Provider<EventLogRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return EventLogRepository(db);
});

final lockScreenRepositoryProvider = Provider<LockScreenRepository>((ref) {
  return LockScreenRepository(ref.watch(appDatabaseProvider));
});

final lockScreenViewModelProvider =
    ChangeNotifierProvider.autoDispose<LockScreenViewModel>((ref) {
      final viewModel = LockScreenViewModel(
        repository: ref.watch(lockScreenRepositoryProvider),
        taskRepository: ref.watch(taskRepositoryProvider),
        blockRepository: ref.watch(blockRepositoryProvider),
      );
      viewModel.load();
      return viewModel;
    });

final lockScreenSyncServiceProvider = Provider<LockScreenSyncService>((ref) {
  return LockScreenSyncService(
    repository: ref.watch(lockScreenRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    blockRepository: ref.watch(blockRepositoryProvider),
  );
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref.watch(appDatabaseProvider));
});

final notesViewModelProvider = ChangeNotifierProvider<NotesViewModel>((ref) {
  final model = NotesViewModel(ref.watch(noteRepositoryProvider));
  model.load();
  return model;
});

final deviceCalendarViewModelProvider =
    ChangeNotifierProvider<DeviceCalendarViewModel>((ref) {
      return DeviceCalendarViewModel(const DeviceCalendarService());
    });

final calendarTaskSyncServiceProvider = Provider<CalendarTaskSyncService>((
  ref,
) {
  return CalendarTaskSyncService(
    taskRepository: ref.watch(taskRepositoryProvider),
    blockRepository: ref.watch(blockRepositoryProvider),
  );
});
