import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/providers/theme_provider.dart';
import 'package:moss/core/theme/app_theme.dart';
import 'package:moss/core/widgets/theme_toggle_button.dart';

void main() {
  group('ThemeModeNotifier', () {
    test('initializes with ThemeMode.system by default', () {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, ThemeMode.system);
    });

    test('cycles theme mode via toggleTheme', () {
      final notifier = ThemeModeNotifier(ThemeMode.system);
      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.dark);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.light);

      notifier.toggleTheme();
      expect(notifier.state, ThemeMode.system);
    });

    test('sets theme mode explicitly', () {
      final notifier = ThemeModeNotifier();
      notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);

      notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
    });
  });

  group('Theme Widgets', () {
    testWidgets('ThemeToggleButton toggles theme on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final mode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                home: Scaffold(
                  body: Center(
                    child: Column(
                      children: [
                        Text('CurrentMode: $mode'),
                        const ThemeToggleButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('CurrentMode: ThemeMode.system'), findsOneWidget);

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      expect(find.text('CurrentMode: ThemeMode.dark'), findsOneWidget);

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      expect(find.text('CurrentMode: ThemeMode.light'), findsOneWidget);
    });

    testWidgets('ThemeSegmentedSelector switches modes directly', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final mode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                home: Scaffold(
                  body: Column(
                    children: [
                      Text('CurrentMode: $mode'),
                      const ThemeSegmentedSelector(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('CurrentMode: ThemeMode.system'), findsOneWidget);

      // Tap 'มืด'
      await tester.tap(find.text('มืด'));
      await tester.pumpAndSettle();
      expect(find.text('CurrentMode: ThemeMode.dark'), findsOneWidget);

      // Tap 'สว่าง'
      await tester.tap(find.text('สว่าง'));
      await tester.pumpAndSettle();
      expect(find.text('CurrentMode: ThemeMode.light'), findsOneWidget);

      // Tap 'ระบบ'
      await tester.tap(find.text('ระบบ'));
      await tester.pumpAndSettle();
      expect(find.text('CurrentMode: ThemeMode.system'), findsOneWidget);
    });
  });
}
