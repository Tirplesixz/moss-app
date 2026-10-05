import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../../features/tasks/data/task_repository.dart';
import '../../features/tasks/data/block_repository.dart';
import '../../features/tasks/data/notif_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../analytics/event_log_repository.dart';

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
