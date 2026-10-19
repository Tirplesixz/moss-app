import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/validation/input_limits.dart';
import '../domain/note.dart';

class NoteRepository {
  NoteRepository(this._database);
  final AppDatabase _database;

  Future<List<Note>> getActiveNotes() async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabaseTables.tableNotes,
      where: 'deleted_at IS NULL',
      orderBy: 'pinned DESC, updated_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<void> save(Note note) async {
    InputLimits.requireNonBlank(note.title, 'title');
    InputLimits.requireAtMost(note.title, InputLimits.noteTitle, 'title');
    InputLimits.requireAtMost(note.content, InputLimits.noteContent, 'content');
    final db = await _database.database;
    await db.insert(
      AppDatabaseTables.tableNotes,
      _toRow(note.copyWith(updatedAt: DateTime.now().toUtc())),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      AppDatabaseTables.tableNotes,
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _database.database;
    await db.update(
      AppDatabaseTables.tableNotes,
      {
        'deleted_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Note _fromRow(Map<String, Object?> row) => Note(
    id: row['id'] as String,
    title: row['title'] as String,
    content: row['content'] as String? ?? '',
    colorValue: row['color_value'] as int? ?? 0xFFFFFFFF,
    pinned: row['pinned'] == 1,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    deletedAt: row['deleted_at'] == null
        ? null
        : DateTime.parse(row['deleted_at'] as String),
  );

  Map<String, Object?> _toRow(Note note) => {
    'id': note.id,
    'title': note.title,
    'content': note.content,
    'color_value': note.colorValue,
    'pinned': note.pinned ? 1 : 0,
    'created_at': note.createdAt.toUtc().toIso8601String(),
    'updated_at': note.updatedAt.toUtc().toIso8601String(),
    'deleted_at': note.deletedAt?.toUtc().toIso8601String(),
  };
}
