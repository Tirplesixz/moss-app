import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme extension for custom tokens from PLAN.md Section 8.
@immutable
class MossThemeExtension extends ThemeExtension<MossThemeExtension> {
  final Color background;
  final Color onBackground;
  final Color primary;
  final Color nowFill;
  final Color nowBorder;
  final Color urgentAccent;
  final Color cardBackground;
  final Color textMuted;
  final Color textSecondary;
  final Color borderSubtle;
  final Color divider;

  const MossThemeExtension({
    required this.background,
    required this.onBackground,
    required this.primary,
    required this.nowFill,
    required this.nowBorder,
    required this.urgentAccent,
    required this.cardBackground,
    required this.textMuted,
    required this.textSecondary,
    required this.borderSubtle,
    required this.divider,
  });

  static const light = MossThemeExtension(
    background: AppColors.background,
    onBackground: AppColors.onBackground,
    primary: AppColors.primary,
    nowFill: AppColors.nowFill,
    nowBorder: AppColors.nowBorder,
    urgentAccent: AppColors.urgentAccent,
    cardBackground: AppColors.cardBackground,
    textMuted: AppColors.textMuted,
    textSecondary: AppColors.textSecondary,
    borderSubtle: AppColors.borderSubtle,
    divider: AppColors.divider,
  );

  @override
  MossThemeExtension copyWith({
    Color? background,
    Color? onBackground,
    Color? primary,
    Color? nowFill,
    Color? nowBorder,
    Color? urgentAccent,
    Color? cardBackground,
    Color? textMuted,
    Color? textSecondary,
    Color? borderSubtle,
    Color? divider,
  }) {
    return MossThemeExtension(
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      primary: primary ?? this.primary,
      nowFill: nowFill ?? this.nowFill,
      nowBorder: nowBorder ?? this.nowBorder,
      urgentAccent: urgentAccent ?? this.urgentAccent,
      cardBackground: cardBackground ?? this.cardBackground,
      textMuted: textMuted ?? this.textMuted,
      textSecondary: textSecondary ?? this.textSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
    );
  }

  @override
  MossThemeExtension lerp(ThemeExtension<MossThemeExtension>? other, double t) {
    if (other is! MossThemeExtension) return this;
    return MossThemeExtension(
      background: Color.lerp(background, other.background, t) ?? background,
      onBackground:
          Color.lerp(onBackground, other.onBackground, t) ?? onBackground,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      nowFill: Color.lerp(nowFill, other.nowFill, t) ?? nowFill,
      nowBorder: Color.lerp(nowBorder, other.nowBorder, t) ?? nowBorder,
      urgentAccent:
          Color.lerp(urgentAccent, other.urgentAccent, t) ?? urgentAccent,
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
    );
  }
}

extension BuildContextThemeExtension on BuildContext {
  MossThemeExtension get mossTheme =>
      Theme.of(this).extension<MossThemeExtension>() ??
      MossThemeExtension.light;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.urgentAccent,
        onSecondary: Colors.white,
        error: AppColors.urgentAccent,
        onError: Colors.white,
        surface: AppColors.cardBackground,
        onSurface: AppColors.onBackground,
      ),
      extensions: const [MossThemeExtension.light],
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: AppColors.onBackground, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.onBackground, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
        ),
      ),
    );
  }
}
