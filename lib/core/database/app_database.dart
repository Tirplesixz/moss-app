import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'tables.dart';
import '../../features/settings/domain/app_settings.dart';

/// Database manager for Moss app.
/// Handles connection lifecycle, schema creation, migrations, and default seeding.
class AppDatabase {
  static const String _databaseName = 'moss.db';
  static const int _databaseVersion = 13;

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
    await db.execute(AppDatabaseTables.createLockScreenConfigsTable);
    await db.execute(AppDatabaseTables.createNotesTable);

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
        'appearance_mode': defaultSettings.appearanceMode,
        'save_completed_to_calendar': 0,
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
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableTasks} '
        'ADD COLUMN checklist TEXT',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableTasks} '
        'ADD COLUMN note TEXT',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableTasks} '
        'ADD COLUMN quadrant INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableTasks} '
        'ADD COLUMN repeat_rule TEXT',
      );
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableSettings} '
        "ADD COLUMN appearance_mode TEXT NOT NULL DEFAULT 'system'",
      );
    }
    if (oldVersion < 8) {
      await db.execute(AppDatabaseTables.createLockScreenConfigsTable);
    }
    if (oldVersion >= 8 && oldVersion < 9) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        'ADD COLUMN auto_update INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        'ADD COLUMN task_limit INTEGER NOT NULL DEFAULT 4',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        "ADD COLUMN module_order TEXT NOT NULL DEFAULT 'clock,progress,tasks,calendar'",
      );
    }
    if (oldVersion < 10) {
      await db.execute(AppDatabaseTables.createNotesTable);
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_updated '
        'ON ${AppDatabaseTables.tableNotes}(pinned DESC, updated_at DESC, deleted_at)',
      );
    }
    if (oldVersion < 11) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableSettings} '
        'ADD COLUMN save_completed_to_calendar INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableTasks} '
        'ADD COLUMN calendar_event_id TEXT',
      );
    }
    if (oldVersion < 13) {
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        'ADD COLUMN vertical_offset REAL NOT NULL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        'ADD COLUMN show_countdown INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        "ADD COLUMN countdown_title TEXT NOT NULL DEFAULT 'วันสำคัญ'",
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        'ADD COLUMN countdown_date TEXT',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        'ADD COLUMN show_pinned_note INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        "ADD COLUMN pinned_note_text TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE ${AppDatabaseTables.tableLockScreenConfigs} '
        'ADD COLUMN dim_past_events INTEGER NOT NULL DEFAULT 0',
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
