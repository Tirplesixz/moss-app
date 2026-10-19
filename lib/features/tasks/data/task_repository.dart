import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/validation/input_limits.dart';
import '../domain/task.dart';

class TaskRepository {
  final AppDatabase _database;

  TaskRepository(this._database);

  Task _fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as String,
      title: row['title'] as String,
      note: row['note'] as String?,
      durationMin: row['duration_min'] as int,
      deadlineAt: row['deadline_at'] != null
          ? TimeUtils.parseUtc(row['deadline_at'] as String)
          : null,
      priority: row['priority'] as int? ?? 2,
      quadrant:
          row['quadrant'] as int? ??
          (row['priority'] == 3 ? 1 : (row['priority'] == 1 ? 2 : 1)),
      projectName: row['project_name'] as String?,
      checklist: _decodeChecklist(row['checklist'] as String?),
      repeatRule: TaskRepeatRule.normalizeStored(row['repeat_rule'] as String?),
      calendarEventId: row['calendar_event_id'] as String?,
      status: TaskStatus.fromString(row['status'] as String? ?? 'todo'),
      createdAt: TimeUtils.parseUtc(row['created_at'] as String),
      updatedAt: TimeUtils.parseUtc(row['updated_at'] as String),
      deletedAt: row['deleted_at'] != null
          ? TimeUtils.parseUtc(row['deleted_at'] as String)
          : null,
    );
  }

  static List<ChecklistItem> _decodeChecklist(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in decoded)
          ChecklistItem.fromMap(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (error, stackTrace) {
      debugPrint('Invalid checklist payload ignored: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  Map<String, dynamic> _toRow(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'note': task.note,
      'duration_min': task.durationMin,
      'deadline_at': task.deadlineAt != null
          ? TimeUtils.toUtcIsoString(task.deadlineAt!)
          : null,
      'priority': task.priority,
      'quadrant': task.quadrant,
      'project_name': task.projectName,
      'checklist': task.checklist.isEmpty
          ? null
          : jsonEncode(task.checklist.map((item) => item.toMap()).toList()),
      'repeat_rule': TaskRepeatRule.normalizeStored(task.repeatRule),
      'calendar_event_id': task.calendarEventId,
      'status': task.status.value,
      'created_at': TimeUtils.toUtcIsoString(task.createdAt),
      'updated_at': TimeUtils.toUtcIsoString(task.updatedAt),
      'deleted_at': task.deletedAt != null
          ? TimeUtils.toUtcIsoString(task.deletedAt!)
          : null,
    };
  }

  Future<void> createTask(Task task) async {
    _validate(task);
    final db = await _database.database;
    await db.insert(
      AppDatabaseTables.tableTasks,
      _toRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(Task task) async {
    _validate(task);
    final db = await _database.database;
    final existing = await getTaskById(task.id);
    final withExternalId =
        task.calendarEventId == null && existing?.calendarEventId != null
        ? task.copyWith(calendarEventId: () => existing!.calendarEventId)
        : task;
    final updated = withExternalId.copyWith(updatedAt: TimeUtils.nowUtc());
    await db.update(
      AppDatabaseTables.tableTasks,
      _toRow(updated),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static void _validate(Task task) {
    InputLimits.requireNonBlank(task.title, 'title');
    InputLimits.requireAtMost(task.title, InputLimits.taskTitle, 'title');
    if (task.note != null) {
      InputLimits.requireAtMost(task.note!, InputLimits.taskNote, 'note');
    }
    if (task.projectName != null) {
      InputLimits.requireAtMost(
        task.projectName!,
        InputLimits.projectName,
        'projectName',
      );
    }
    for (final item in task.checklist) {
      InputLimits.requireAtMost(
        item.title,
        InputLimits.checklistItem,
        'checklistItem',
      );
    }
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    final db = await _database.database;
    await db.update(
      AppDatabaseTables.tableTasks,
      {
        'status': status.value,
        'updated_at': TimeUtils.toUtcIsoString(TimeUtils.nowUtc()),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [taskId],
    );
  }

  Future<void> setCalendarEventId(String taskId, String? eventId) async {
    final db = await _database.database;
    await db.update(
      AppDatabaseTables.tableTasks,
      {
        'calendar_event_id': eventId,
        'updated_at': TimeUtils.toUtcIsoString(TimeUtils.nowUtc()),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [taskId],
    );
  }

  Future<void> softDeleteTask(String taskId) async {
    final db = await _database.database;
    final now = TimeUtils.toUtcIsoString(TimeUtils.nowUtc());
    await db.update(
      AppDatabaseTables.tableTasks,
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Undoes [softDeleteTask].
  Future<void> restoreTask(String taskId) async {
    final db = await _database.database;
    await db.update(
      AppDatabaseTables.tableTasks,
      {
        'deleted_at': null,
        'updated_at': TimeUtils.toUtcIsoString(TimeUtils.nowUtc()),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<Task?> getTaskById(String taskId) async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableTasks,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [taskId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _fromRow(results.first);
  }

  Future<List<Task>> getActiveTodoTasks() async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableTasks,
      where: "status = 'todo' AND deleted_at IS NULL",
      orderBy:
          "deadline_at IS NULL, deadline_at ASC, priority DESC, created_at ASC",
    );
    return results.map(_fromRow).toList();
  }

  Future<List<Task>> getAllActiveTasks() async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableTasks,
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return results.map(_fromRow).toList();
  }
}
