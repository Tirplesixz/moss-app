import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/time_utils.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  final AppDatabase _database;

  SettingsRepository(this._database);

  AppSettings _fromRow(Map<String, dynamic> row) {
    return AppSettings(
      id: row['id'] as String,
      workdayStart: row['workday_start'] as String? ?? '09:00',
      workdayEnd: row['workday_end'] as String? ?? '18:00',
      bufferMin: row['buffer_min'] as int? ?? 5,
      timezone: row['timezone'] as String? ?? 'Asia/Bangkok',
      onboardingComplete: (row['onboarding_complete'] as int? ?? 0) == 1,
      paywallInterestCount: row['paywall_interest_count'] as int? ?? 0,
      updatedAt: TimeUtils.parseUtc(row['updated_at'] as String),
      deletedAt: row['deleted_at'] != null
          ? TimeUtils.parseUtc(row['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> _toRow(AppSettings settings) {
    return {
      'id': settings.id,
      'workday_start': settings.workdayStart,
      'workday_end': settings.workdayEnd,
      'buffer_min': settings.bufferMin,
      'timezone': settings.timezone,
      'onboarding_complete': settings.onboardingComplete ? 1 : 0,
      'paywall_interest_count': settings.paywallInterestCount,
      'updated_at': TimeUtils.toUtcIsoString(settings.updatedAt),
      'deleted_at': settings.deletedAt != null
          ? TimeUtils.toUtcIsoString(settings.deletedAt!)
          : null,
    };
  }

  Future<AppSettings> getSettings() async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableSettings,
      where: 'deleted_at IS NULL',
      limit: 1,
    );

    if (results.isEmpty) {
      final defaultSettings = AppSettings.createDefault();
      await db.insert(
        AppDatabaseTables.tableSettings,
        _toRow(defaultSettings),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return defaultSettings;
    }

    return _fromRow(results.first);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await _database.database;
    final updated = settings.copyWith(updatedAt: TimeUtils.nowUtc());
    await db.insert(
      AppDatabaseTables.tableSettings,
      _toRow(updated),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
