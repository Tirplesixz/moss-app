import 'package:flutter/material.dart';

/// Shared motion tokens for predictable, accessible transitions.
class MossMotion {
  MossMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration emphasis = Duration(milliseconds: 320);
  static const Duration stagger = Duration(milliseconds: 40);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve stateCurve = Curves.easeInOutCubic;

  static Duration duration(BuildContext context, Duration preferred) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : preferred;
  }
}
