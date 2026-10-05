import 'package:moss/core/database/app_database.dart';
import 'package:moss/core/database/tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

Future<AppDatabase> createTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
  await db.execute(AppDatabaseTables.createTasksTable);
  await db.execute(AppDatabaseTables.createBlocksTable);
  await db.execute(AppDatabaseTables.createSettingsTable);
  await db.execute(AppDatabaseTables.createNotifsTable);
  await db.execute(AppDatabaseTables.createEventsTable);
  for (final index in AppDatabaseTables.createIndices) {
    await db.execute(index);
  }
  final appDatabase = AppDatabase(customDb: db);
  addTearDown(appDatabase.close);
  return appDatabase;
}

Future<void> settleDatabaseIo(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump();
}

Future<void> disposeTestDatabase(
  WidgetTester tester,
  AppDatabase database,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await database.close();
}
