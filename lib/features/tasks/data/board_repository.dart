import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../domain/matrix_board.dart';

class BoardRepository {
  final AppDatabase _database;

  BoardRepository(this._database);

  Future<Database> get _db => _database.database;

  Future<List<MatrixBoard>> getAllBoards() async {
    final db = await _db;
    final maps = await db.query(
      AppDatabaseTables.tableBoards,
      where: 'deleted_at IS NULL',
      orderBy: 'is_default DESC, created_at ASC',
    );

    if (maps.isEmpty) {
      // Seed defaults if empty
      final defaults = MatrixBoard.createDefaults();
      for (final b in defaults) {
        await db.insert(
          AppDatabaseTables.tableBoards,
          b.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return defaults;
    }

    return maps.map((m) => MatrixBoard.fromMap(m)).toList();
  }

  Future<MatrixBoard?> getBoardById(String id) async {
    final db = await _db;
    final maps = await db.query(
      AppDatabaseTables.tableBoards,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MatrixBoard.fromMap(maps.first);
  }

  Future<void> saveBoard(MatrixBoard board) async {
    final db = await _db;
    await db.insert(
      AppDatabaseTables.tableBoards,
      board.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBoard(MatrixBoard board) async {
    final db = await _db;
    await db.update(
      AppDatabaseTables.tableBoards,
      board.toMap(),
      where: 'id = ?',
      whereArgs: [board.id],
    );
  }

  Future<void> deleteBoard(String id) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      AppDatabaseTables.tableBoards,
      {'deleted_at': now},
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }
}
