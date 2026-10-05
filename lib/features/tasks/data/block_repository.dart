import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/time_utils.dart';
import '../domain/block.dart';

class BlockRepository {
  final AppDatabase _database;

  BlockRepository(this._database);

  Block _fromRow(Map<String, dynamic> row) {
    return Block(
      id: row['id'] as String,
      kind: BlockKind.fromString(row['kind'] as String? ?? 'task'),
      taskId: row['task_id'] as String?,
      title: row['title'] as String?,
      startAt: TimeUtils.parseUtc(row['start_at'] as String),
      endAt: TimeUtils.parseUtc(row['end_at'] as String),
      locked: (row['locked'] as int? ?? 0) == 1,
      source: row['source'] as String? ?? 'local',
      externalId: row['external_id'] as String?,
      createdAt: TimeUtils.parseUtc(row['created_at'] as String),
      updatedAt: TimeUtils.parseUtc(row['updated_at'] as String),
      deletedAt: row['deleted_at'] != null
          ? TimeUtils.parseUtc(row['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> _toRow(Block block) {
    return {
      'id': block.id,
      'kind': block.kind.value,
      'task_id': block.taskId,
      'title': block.title,
      'start_at': TimeUtils.toUtcIsoString(block.startAt),
      'end_at': TimeUtils.toUtcIsoString(block.endAt),
      'locked': block.locked ? 1 : 0,
      'source': block.source,
      'external_id': block.externalId,
      'created_at': TimeUtils.toUtcIsoString(block.createdAt),
      'updated_at': TimeUtils.toUtcIsoString(block.updatedAt),
      'deleted_at': block.deletedAt != null
          ? TimeUtils.toUtcIsoString(block.deletedAt!)
          : null,
    };
  }

  Future<void> createBlock(Block block) async {
    final db = await _database.database;
    await db.insert(
      AppDatabaseTables.tableBlocks,
      _toRow(block),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBlock(Block block) async {
    final db = await _database.database;
    final updated = block.copyWith(updatedAt: TimeUtils.nowUtc());
    await db.update(
      AppDatabaseTables.tableBlocks,
      _toRow(updated),
      where: 'id = ?',
      whereArgs: [block.id],
    );
  }

  Future<void> softDeleteBlock(String blockId) async {
    final db = await _database.database;
    final now = TimeUtils.toUtcIsoString(TimeUtils.nowUtc());
    await db.update(
      AppDatabaseTables.tableBlocks,
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [blockId],
    );
  }

  Future<Block?> getBlockById(String blockId) async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableBlocks,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [blockId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _fromRow(results.first);
  }

  /// Returns all active blocks overlapping a time range [startUtc, endUtc].
  Future<List<Block>> getBlocksInRange(
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final db = await _database.database;
    final startStr = TimeUtils.toUtcIsoString(startUtc);
    final endStr = TimeUtils.toUtcIsoString(endUtc);

    final results = await db.query(
      AppDatabaseTables.tableBlocks,
      where: 'deleted_at IS NULL AND start_at < ? AND end_at > ?',
      whereArgs: [endStr, startStr],
      orderBy: 'start_at ASC',
    );
    return results.map(_fromRow).toList();
  }

  /// Returns all active blocks for a given day in local time.
  Future<List<Block>> getBlocksForDay(DateTime localDate) async {
    final startOfDayLocal = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      0,
      0,
      0,
    );
    final endOfDayLocal = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
    return getBlocksInRange(startOfDayLocal.toUtc(), endOfDayLocal.toUtc());
  }

  /// Returns all active fixed blocks (meetings/appointments).
  Future<List<Block>> getActiveFixedBlocks() async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableBlocks,
      where: "kind = 'fixed' AND deleted_at IS NULL",
      orderBy: 'start_at ASC',
    );
    return results.map(_fromRow).toList();
  }

  Future<List<Block>> getActiveBlocks() async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableBlocks,
      where: 'deleted_at IS NULL',
      orderBy: 'start_at ASC',
    );
    return results.map(_fromRow).toList();
  }

  /// Replaces movable task blocks with a newly scheduled list of blocks in a transaction.
  Future<void> replaceMovableTaskBlocks(
    List<Block> newBlocks,
    DateTime fromTimeUtc,
  ) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final nowStr = TimeUtils.toUtcIsoString(TimeUtils.nowUtc());
      final fromStr = TimeUtils.toUtcIsoString(fromTimeUtc);

      // Soft delete existing movable task blocks starting on or after fromTimeUtc
      await txn.update(
        AppDatabaseTables.tableBlocks,
        {'deleted_at': nowStr, 'updated_at': nowStr},
        where:
            "kind = 'task' AND locked = 0 AND start_at >= ? AND deleted_at IS NULL",
        whereArgs: [fromStr],
      );

      // Insert new blocks
      final batch = txn.batch();
      for (final block in newBlocks) {
        batch.insert(
          AppDatabaseTables.tableBlocks,
          _toRow(block),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> replaceAllMovableTaskBlocks(List<Block> newBlocks) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final nowStr = TimeUtils.toUtcIsoString(TimeUtils.nowUtc());
      await txn.update(
        AppDatabaseTables.tableBlocks,
        {'deleted_at': nowStr, 'updated_at': nowStr},
        where: "kind = 'task' AND locked = 0 AND deleted_at IS NULL",
      );

      final batch = txn.batch();
      for (final block in newBlocks) {
        batch.insert(
          AppDatabaseTables.tableBlocks,
          _toRow(block),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
