import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moss/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding and all five destinations remain reachable', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MossApp()));
    await tester.pump(const Duration(seconds: 2));

    final onboardingButton = find.text('เริ่มจัดวันนี้');
    if (onboardingButton.evaluate().isNotEmpty) {
      await tester.tap(onboardingButton);
      await tester.pump(const Duration(seconds: 2));
    }

    for (final destination in const [
      'today',
      'inbox',
      'calendar',
      'notes',
      'settings',
    ]) {
      final target = find.byKey(ValueKey('nav-$destination'));
      expect(target, findsOneWidget);
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
  });
}
