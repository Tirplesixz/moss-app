import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/utils/time_utils.dart';
import '../domain/notif.dart';

class NotifRepository {
  final AppDatabase _database;

  NotifRepository(this._database);

  Notif _fromRow(Map<String, dynamic> row) {
    return Notif(
      id: row['id'] as String,
      blockId: row['block_id'] as String,
      type: NotifType.fromString(row['type'] as String? ?? 'start'),
      fireAt: TimeUtils.parseUtc(row['fire_at'] as String),
      osNotifId: row['os_notif_id'] as int,
      createdAt: TimeUtils.parseUtc(row['created_at'] as String),
      updatedAt: TimeUtils.parseUtc(row['updated_at'] as String),
      deletedAt: row['deleted_at'] != null
          ? TimeUtils.parseUtc(row['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> _toRow(Notif notif) {
    return {
      'id': notif.id,
      'block_id': notif.blockId,
      'type': notif.type.value,
      'fire_at': TimeUtils.toUtcIsoString(notif.fireAt),
      'os_notif_id': notif.osNotifId,
      'created_at': TimeUtils.toUtcIsoString(notif.createdAt),
      'updated_at': TimeUtils.toUtcIsoString(notif.updatedAt),
      'deleted_at': notif.deletedAt != null
          ? TimeUtils.toUtcIsoString(notif.deletedAt!)
          : null,
    };
  }

  Future<void> createNotif(Notif notif) async {
    final db = await _database.database;
    await db.insert(
      AppDatabaseTables.tableNotifs,
      _toRow(notif),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteNotifsForBlock(String blockId) async {
    final db = await _database.database;
    final now = TimeUtils.toUtcIsoString(TimeUtils.nowUtc());
    await db.update(
      AppDatabaseTables.tableNotifs,
      {'deleted_at': now, 'updated_at': now},
      where: 'block_id = ? AND deleted_at IS NULL',
      whereArgs: [blockId],
    );
  }

  Future<List<Notif>> getUpcomingNotifs(DateTime horizonUtc) async {
    final db = await _database.database;
    final nowStr = TimeUtils.toUtcIsoString(TimeUtils.nowUtc());
    final horizonStr = TimeUtils.toUtcIsoString(horizonUtc);

    final results = await db.query(
      AppDatabaseTables.tableNotifs,
      where: 'deleted_at IS NULL AND fire_at >= ? AND fire_at <= ?',
      whereArgs: [nowStr, horizonStr],
      orderBy: 'fire_at ASC',
    );
    return results.map(_fromRow).toList();
  }

  Future<List<Notif>> getNotifsForBlock(String blockId) async {
    final db = await _database.database;
    final results = await db.query(
      AppDatabaseTables.tableNotifs,
      where: 'block_id = ? AND deleted_at IS NULL',
      whereArgs: [blockId],
    );
    return results.map(_fromRow).toList();
  }
}
