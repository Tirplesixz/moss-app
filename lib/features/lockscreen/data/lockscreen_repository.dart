import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../domain/lockscreen_config.dart';

class LockScreenRepository {
  LockScreenRepository(this._database);

  final AppDatabase _database;

  Future<LockScreenConfig> loadActive() async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabaseTables.tableLockScreenConfigs,
      where: 'id = ?',
      whereArgs: [LockScreenConfig.activeId],
      limit: 1,
    );
    if (rows.isEmpty) return LockScreenConfig.initial();
    final row = rows.first;
    return LockScreenConfig(
      templateId: row['template_id'] as String,
      gradientStart: row['gradient_start'] as int,
      gradientEnd: row['gradient_end'] as int,
      showClock: row['show_clock'] == 1,
      showProgress: row['show_progress'] == 1,
      showTasks: row['show_tasks'] == 1,
      showCalendar: row['show_calendar'] == 1,
      autoUpdate: (row['auto_update'] as int? ?? 0) == 1,
      taskLimit: row['task_limit'] as int? ?? 4,
      moduleOrder:
          ((row['module_order'] as String?) ?? 'clock,countdown,progress,tasks,calendar,note')
              .split(','),
      verticalOffset: (row['vertical_offset'] as num?)?.toDouble() ?? 0.0,
      showCountdown: (row['show_countdown'] as int? ?? 0) == 1,
      countdownTitle: (row['countdown_title'] as String?) ?? 'วันสำคัญ',
      countdownDate: row['countdown_date'] as String?,
      showPinnedNote: (row['show_pinned_note'] as int? ?? 0) == 1,
      pinnedNoteText: (row['pinned_note_text'] as String?) ?? '',
      dimPastEvents: (row['dim_past_events'] as int? ?? 0) == 1,
      showYearProgress: (row['show_year_progress'] as int? ?? 0) == 1,
      paperStyle: (row['paper_style'] as String?) ?? 'plain',
      updatedAt: DateTime.parse(row['updated_at'] as String),
      lastRenderedAt: row['last_rendered_at'] == null
          ? null
          : DateTime.parse(row['last_rendered_at'] as String),
    );
  }

  Future<void> save(LockScreenConfig config) async {
    final db = await _database.database;
    await db.insert(
      AppDatabaseTables.tableLockScreenConfigs,
      {
        'id': LockScreenConfig.activeId,
        'template_id': config.templateId,
        'gradient_start': config.gradientStart,
        'gradient_end': config.gradientEnd,
        'show_clock': config.showClock ? 1 : 0,
        'show_progress': config.showProgress ? 1 : 0,
        'show_tasks': config.showTasks ? 1 : 0,
        'show_calendar': config.showCalendar ? 1 : 0,
        'auto_update': config.autoUpdate ? 1 : 0,
        'task_limit': config.taskLimit,
        'module_order': config.moduleOrder.join(','),
        'vertical_offset': config.verticalOffset,
        'show_countdown': config.showCountdown ? 1 : 0,
        'countdown_title': config.countdownTitle,
        'countdown_date': config.countdownDate,
        'show_pinned_note': config.showPinnedNote ? 1 : 0,
        'pinned_note_text': config.pinnedNoteText,
        'dim_past_events': config.dimPastEvents ? 1 : 0,
        'show_year_progress': config.showYearProgress ? 1 : 0,
        'paper_style': config.paperStyle,
        'updated_at': config.updatedAt.toUtc().toIso8601String(),
        'last_rendered_at': config.lastRenderedAt?.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
