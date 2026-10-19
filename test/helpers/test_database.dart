import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/database/app_database.dart';
import 'package:moss/core/database/tables.dart';
import 'package:moss/features/settings/domain/app_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<AppDatabase> createTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
  await db.execute(AppDatabaseTables.createTasksTable);
  await db.execute(AppDatabaseTables.createBlocksTable);
  await db.execute(AppDatabaseTables.createSettingsTable);
  await db.execute(AppDatabaseTables.createNotifsTable);
  await db.execute(AppDatabaseTables.createEventsTable);
  await db.execute(AppDatabaseTables.createLockScreenConfigsTable);
  await db.execute(AppDatabaseTables.createNotesTable);
  for (final index in AppDatabaseTables.createIndices) {
    await db.execute(index);
  }
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
      'save_completed_to_calendar':
          defaultSettings.saveCompletedToCalendar ? 1 : 0,
      'updated_at': defaultSettings.updatedAt.toUtc().toIso8601String(),
      'deleted_at': null,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
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
  await tester.runAsync(() => database.close());
  await tester.pump();
}
