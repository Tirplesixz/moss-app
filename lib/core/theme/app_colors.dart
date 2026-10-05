import 'package:flutter/material.dart';

/// Design tokens specified in PLAN.md Section 8.
/// Never hardcode colors in widgets; use these tokens or Theme.of(context).
class AppColors {
  AppColors._();

  // Primary design tokens (PLAN.md Section 8)
  static const Color background = Color(0xFFFBF6EC); // Warm, calm canvas
  static const Color onBackground = Color(0xFF3A2F2A); // Warm charcoal
  static const Color primary = Color(0xFF4A7A58); // Moss green
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on primary
  static const Color nowFill = Color(0xFFEAF2E8); // Soft moss tint
  static const Color nowBorder = Color(0xFFAFC9B4); // Active task border
  static const Color urgentAccent = Color(0xFFD47B45); // Warm urgent accent

  // Neutral & semantic supporting tokens
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A8178);
  static const Color textSecondary = Color(0xFF625B54);
  static const Color borderSubtle = Color(0xFFEAE2D5);
  static const Color divider = Color(0xFFE6DED1);
  static const Color success = Color(0xFF4A7A58);
  static const Color overflowWarning = Color(0xFFC98237);
}
