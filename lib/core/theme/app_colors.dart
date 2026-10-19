import 'package:flutter/material.dart';

/// Legacy compatibility colors for the Moss design system.
class AppColors {
  AppColors._();

  // Legacy dark palette. New and migrated widgets consume semantic colors
  // from Theme.of(context) / MossThemeExtension instead.
  static const Color background = Color(0xFF0D0F14);
  static const Color onBackground = Color(0xFFF9FAFB);
  static const Color cardBackground = Color(0xFF161922);
  static const Color cardElevated = Color(0xFF1E2330);
  static const Color cardMuted = Color(0xFF141720);
  static const Color pillBackground = Color(0xFF202534);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFF343B4C);
  static const Color borderLight = Color(0xFF454E62);
  static const Color divider = Color(0xFF2B3140);

  // Typography
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFFB8BFCC);
  static const Color textMuted = Color(0xFF9AA3B3);

  // Eisenhower Matrix Quadrant Palettes
  // Q1: สำคัญและเร่งด่วน (Urgent & Important)
  static const Color quadrant1 = Color(0xFFFF453A);
  static const Color quadrant1Bg = Color(0xFF241618);
  static const Color quadrant1Border = Color(0xFF3E1F23);
  static const Color quadrant1Fill = Color(0xFF2D1B1E);

  // Q2: สำคัญ (Important)
  static const Color quadrant2 = Color(0xFF0A84FF);
  static const Color quadrant2Bg = Color(0xFF121B2B);
  static const Color quadrant2Border = Color(0xFF1A2A44);
  static const Color quadrant2Fill = Color(0xFF172338);

  // Q3: เร่งด่วน (Urgent)
  static const Color quadrant3 = Color(0xFFFFD60A);
  static const Color quadrant3Bg = Color(0xFF221F13);
  static const Color quadrant3Border = Color(0xFF3D3717);
  static const Color quadrant3Fill = Color(0xFF2D2817);

  // Q4: สักวันหนึ่ง (Someday)
  static const Color quadrant4 = Color(0xFF8E8E93);
  static const Color quadrant4Bg = Color(0xFF181B22);
  static const Color quadrant4Border = Color(0xFF282D3A);
  static const Color quadrant4Fill = Color(0xFF20242F);

  // Status & Utility
  static const Color success = Color(0xFF30D158);
  static const Color streak = Color(0xFFFF9500);
  static const Color primary = Color(0xFF9B78FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color fabBackground = primary;
  static const Color fabIcon = Color(0xFFFFFFFF);

  // Legacy mappings for backwards compatibility
  static const Color nowFill = Color(0xFF1E2330);
  static const Color nowBorder = Color(0xFF0A84FF);
  static const Color urgentAccent = Color(0xFFFF453A);
  static const Color overflowWarning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);

  static Color quadrantFor(int quadrant) => switch (quadrant) {
    1 => quadrant1,
    2 => quadrant2,
    3 => quadrant3,
    _ => quadrant4,
  };
}
