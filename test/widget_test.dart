import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/providers/database_providers.dart';
import 'package:moss/main.dart';

import 'helpers/test_database.dart';

void main() {
  testWidgets('first launch shows Moss onboarding', (tester) async {
    final database = await createTestDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MossApp(),
      ),
    );
    await settleDatabaseIo(tester);

    expect(find.text('งานด่วนเข้า\nก็ยังไม่ลน'), findsOneWidget);
    expect(find.text('เริ่มจัดวันนี้'), findsOneWidget);
    await disposeTestDatabase(tester, database);
  });
}
