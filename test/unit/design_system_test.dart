import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moss/core/theme/app_primitives.dart';
import 'package:moss/core/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Moss design system', () {
    test('spacing tokens follow a 4dp scale', () {
      const values = [
        MossSpacing.x1,
        MossSpacing.x2,
        MossSpacing.x3,
        MossSpacing.x4,
        MossSpacing.x5,
        MossSpacing.x6,
        MossSpacing.x8,
        MossSpacing.x10,
        MossSpacing.x12,
      ];
      expect(values.every((value) => value % 4 == 0), isTrue);
    });

    test('light and dark text pairs meet WCAG AA', () {
      expect(
        _contrast(
          MossThemeExtension.light.onBackground,
          MossThemeExtension.light.background,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          MossThemeExtension.light.textMuted,
          MossThemeExtension.light.background,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          MossThemeExtension.dark.onBackground,
          MossThemeExtension.dark.background,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          MossThemeExtension.dark.textMuted,
          MossThemeExtension.dark.background,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('themes expose semantic and component layers', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<MossThemeExtension>(), isNotNull);
      expect(light.extension<MossComponentTheme>(), isNotNull);
      expect(dark.extension<MossThemeExtension>(), isNotNull);
      expect(dark.extension<MossComponentTheme>(), isNotNull);
      expect(light.textTheme.bodyLarge?.fontSize, MossTypeSizes.body);
    });
  });
}
