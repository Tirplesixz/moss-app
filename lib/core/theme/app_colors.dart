import 'package:flutter/material.dart';

import 'app_primitives.dart';

/// Design tokens specified in PLAN.md Section 8.
/// Never hardcode colors in widgets; use these tokens or Theme.of(context).
class AppColors {
  AppColors._();

  // Primary design tokens (PLAN.md Section 8)
  static const Color background = MossPrimitives.white;
  static const Color onBackground = MossPrimitives.neutral900;
  static const Color primary = MossPrimitives.moss600;
  static const Color onPrimary = MossPrimitives.white;
  static const Color nowFill = MossPrimitives.moss50;
  static const Color nowBorder = MossPrimitives.moss600;
  static const Color urgentAccent = MossPrimitives.orange500;

  // Neutral & semantic supporting tokens
  static const Color cardBackground = MossPrimitives.white;
  static const Color textMuted = MossPrimitives.neutral500;
  static const Color textSecondary = MossPrimitives.neutral600;
  static const Color borderSubtle = MossPrimitives.neutral200;
  static const Color divider = MossPrimitives.neutral100;
  static const Color success = MossPrimitives.moss600;
  static const Color overflowWarning = MossPrimitives.amber500;
  static const Color error = MossPrimitives.red500;
  static const Color info = MossPrimitives.blue500;
}
