import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../utils/time_utils.dart';

class LocalEvent {
  final String name;
  final DateTime occurredAt;
  final Map<String, Object?> properties;

  const LocalEvent({
    required this.name,
    required this.occurredAt,
    this.properties = const {},
  });
}

class EventLogRepository {
  EventLogRepository(this._database);

  static const _uuid = Uuid();
  final AppDatabase _database;

  Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    final db = await _database.database;
    await db.insert(AppDatabaseTables.tableEvents, {
      'id': _uuid.v4(),
      'name': name,
      'occurred_at': TimeUtils.toUtcIsoString(TimeUtils.nowUtc()),
      'properties': jsonEncode(properties),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LocalEvent>> getEvents() async {
    final db = await _database.database;
    final rows = await db.query(
      AppDatabaseTables.tableEvents,
      orderBy: 'occurred_at ASC',
    );
    return rows.map((row) {
      final raw = row['properties'] as String?;
      return LocalEvent(
        name: row['name'] as String,
        occurredAt: TimeUtils.parseUtc(row['occurred_at'] as String),
        properties: raw == null
            ? const {}
            : Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    }).toList();
  }
}
