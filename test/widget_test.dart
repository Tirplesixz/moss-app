import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/main.dart';

import 'helpers/test_database.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz.initializeTimeZones();
  });

  testWidgets('first launch shows Moss onboarding', (tester) async {
    final database = await createTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MossApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('งานด่วนเข้า\nก็ยังไม่ลน'), findsOneWidget);
    expect(find.text('เริ่มจัดวันนี้'), findsOneWidget);
  });
}
