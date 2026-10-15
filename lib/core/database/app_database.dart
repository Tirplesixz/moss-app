import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'tables.dart';
import '../../features/settings/domain/app_settings.dart';

/// Database manager for Moss app.
/// Handles connection lifecycle, schema creation, migrations, and default seeding.
class AppDatabase {
  static const String _databaseName = 'moss.db';
  static const int _databaseVersion = 3;

  Database? _db;

  AppDatabase({Database? customDb}) : _db = customDb;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints in SQLite
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(AppDatabaseTables.createTasksTable);
    await db.execute(AppDatabaseTables.createBlocksTable);
    await db.execute(AppDatabaseTables.createSettingsTable);
    await db.execute(AppDatabaseTables.createNotifsTable);
    await db.execute(AppDatabaseTables.createEventsTable);

    for (final indexSql in AppDatabaseTables.createIndices) {
      await db.execute(indexSql);
    }

    // Seed default settings on initial creation
    final defaultSettings = AppSettings.createDefault();
    await db.insert(
      AppDatabaseTables.tableSettings,
      {
        'id': defaultSettings.id,
        'workday_start': defaultSettings.workdayStart,
        'workday_end': defaultSettings.workdayEnd,
        'buffer_min': defaultSettings.bufferMin,
        'timezone': defaultSettings.timezone,
        'onboarding_complete': defaultSettings.onboardingComplete ? 1 : 0,
        'paywall_interest_count': defaultSettings.paywallInterestCount,
        'updated_at': defaultSettings.updatedAt.toUtc().toIso8601String(),
        'deleted_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableSettings} '
        'ADD COLUMN onboarding_complete INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableSettings} '
        'ADD COLUMN paywall_interest_count INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(AppDatabaseTables.createEventsTable);
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_events_time '
        'ON ${AppDatabaseTables.tableEvents}(occurred_at)',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableTasks} '
        'ADD COLUMN project_name TEXT',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_project '
        'ON ${AppDatabaseTables.tableTasks}(project_name, deleted_at)',
      );
    }
    debugPrint('Upgraded database from $oldVersion to $newVersion');
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
