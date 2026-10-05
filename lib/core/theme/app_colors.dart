import 'package:flutter/material.dart';

/// Design tokens specified in PLAN.md Section 8.
/// Never hardcode colors in widgets; use these tokens or Theme.of(context).
class AppColors {
  AppColors._();

  // Primary design tokens (PLAN.md Section 8)
  static const Color background = Color(0xFFFFFFFF); // Clean calendar canvas
  static const Color onBackground = Color(0xFF202124); // Neutral ink
  static const Color primary = Color(0xFF4D725F); // Moss green
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on primary
  static const Color nowFill = Color(0xFFF0F7F3); // Soft moss tint
  static const Color nowBorder = Color(0xFF9FC6B0); // Active task border
  static const Color urgentAccent = Color(0xFFD56D45); // Warm urgent accent

  // Neutral & semantic supporting tokens
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A9098);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color borderSubtle = Color(0xFFE3E7EA);
  static const Color divider = Color(0xFFEDF0F2);
  static const Color success = Color(0xFF4D725F);
  static const Color overflowWarning = Color(0xFFC98237);
}
