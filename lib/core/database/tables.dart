/// SQL Table definitions and migration statements according to PLAN.md Section 5.
class AppDatabaseTables {
  AppDatabaseTables._();

  static const String tableTasks = 'tasks';
  static const String tableBlocks = 'blocks';
  static const String tableSettings = 'settings';
  static const String tableNotifs = 'notifs';
  static const String tableEvents = 'events';
  static const String tableLockScreenConfigs = 'lockscreen_configs';

  static const String createTasksTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableTasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      duration_min INTEGER NOT NULL,
      deadline_at TEXT,
      priority INTEGER NOT NULL DEFAULT 2,
      project_name TEXT,
      checklist TEXT,
      note TEXT,
      quadrant INTEGER NOT NULL DEFAULT 1,
      repeat_rule TEXT,
      calendar_event_id TEXT,
      status TEXT NOT NULL DEFAULT 'todo',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT
    );
  ''';

  static const String createBlocksTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableBlocks (
      id TEXT PRIMARY KEY,
      kind TEXT NOT NULL DEFAULT 'task',
      task_id TEXT,
      title TEXT,
      start_at TEXT NOT NULL,
      end_at TEXT NOT NULL,
      locked INTEGER NOT NULL DEFAULT 0,
      source TEXT NOT NULL DEFAULT 'local',
      external_id TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      FOREIGN KEY (task_id) REFERENCES $tableTasks (id) ON DELETE SET NULL
    );
  ''';

  static const String createSettingsTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableSettings (
      id TEXT PRIMARY KEY,
      workday_start TEXT NOT NULL DEFAULT '09:00',
      workday_end TEXT NOT NULL DEFAULT '18:00',
      buffer_min INTEGER NOT NULL DEFAULT 5,
      timezone TEXT NOT NULL DEFAULT 'Asia/Bangkok',
      onboarding_complete INTEGER NOT NULL DEFAULT 0,
      paywall_interest_count INTEGER NOT NULL DEFAULT 0,
      appearance_mode TEXT NOT NULL DEFAULT 'system',
      save_completed_to_calendar INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      deleted_at TEXT
    );
  ''';

  static const String createNotifsTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableNotifs (
      id TEXT PRIMARY KEY,
      block_id TEXT NOT NULL,
      type TEXT NOT NULL,
      fire_at TEXT NOT NULL,
      os_notif_id INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      FOREIGN KEY (block_id) REFERENCES $tableBlocks (id) ON DELETE CASCADE
    );
  ''';

  static const String createEventsTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableEvents (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      occurred_at TEXT NOT NULL,
      properties TEXT
    );
  ''';

  static const String createLockScreenConfigsTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableLockScreenConfigs (
      id TEXT PRIMARY KEY,
      template_id TEXT NOT NULL,
      gradient_start INTEGER NOT NULL,
      gradient_end INTEGER NOT NULL,
      show_clock INTEGER NOT NULL DEFAULT 1,
      show_progress INTEGER NOT NULL DEFAULT 1,
      show_tasks INTEGER NOT NULL DEFAULT 1,
      show_calendar INTEGER NOT NULL DEFAULT 0,
      auto_update INTEGER NOT NULL DEFAULT 0,
      task_limit INTEGER NOT NULL DEFAULT 4,
      module_order TEXT NOT NULL DEFAULT 'clock,progress,tasks,calendar',
      vertical_offset REAL NOT NULL DEFAULT 0.0,
      show_countdown INTEGER NOT NULL DEFAULT 0,
      countdown_title TEXT NOT NULL DEFAULT 'วันสำคัญ',
      countdown_date TEXT,
      show_pinned_note INTEGER NOT NULL DEFAULT 0,
      pinned_note_text TEXT NOT NULL DEFAULT '',
      dim_past_events INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      last_rendered_at TEXT
    );
  ''';

  static const String tableNotes = 'notes';

  static const String createNotesTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableNotes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      content TEXT NOT NULL DEFAULT '',
      color_value INTEGER NOT NULL DEFAULT 4294967295,
      pinned INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT
    );
  ''';

  static const List<String> createIndices = [
    'CREATE INDEX IF NOT EXISTS idx_tasks_status ON $tableTasks(status, deleted_at);',
    'CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON $tableTasks(deadline_at);',
    'CREATE INDEX IF NOT EXISTS idx_tasks_project ON $tableTasks(project_name, deleted_at);',
    'CREATE INDEX IF NOT EXISTS idx_blocks_time ON $tableBlocks(start_at, end_at, deleted_at);',
    'CREATE INDEX IF NOT EXISTS idx_blocks_task_id ON $tableBlocks(task_id);',
    'CREATE INDEX IF NOT EXISTS idx_notifs_fire_at ON $tableNotifs(fire_at, deleted_at);',
    'CREATE INDEX IF NOT EXISTS idx_events_time ON $tableEvents(occurred_at);',
    'CREATE INDEX IF NOT EXISTS idx_notes_updated ON $tableNotes(pinned DESC, updated_at DESC, deleted_at);',
  ];
}
