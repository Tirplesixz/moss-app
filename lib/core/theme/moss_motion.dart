import 'package:flutter/material.dart';

/// Shared motion tokens for predictable, accessible transitions.
class MossMotion {
  MossMotion._();

  static const Duration press = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration emphasis = Duration(milliseconds: 280);
  static const Duration exit = Duration(milliseconds: 160);
  static const Duration stagger = Duration(milliseconds: 40);

  static const Curve enterCurve = Cubic(0.23, 1, 0.32, 1);
  static const Curve stateCurve = Cubic(0.77, 0, 0.175, 1);

  static Duration duration(BuildContext context, Duration preferred) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : preferred;
  }

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
