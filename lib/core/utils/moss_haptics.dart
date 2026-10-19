import 'dart:async';

import 'package:flutter/services.dart';

/// Central haptic vocabulary so feedback stays consistent across the app.
///
/// Every call is fire-and-forget and swallows platform errors: haptics are an
/// enhancement and must never break a flow (e.g. on desktop or in tests).
class MossHaptics {
  MossHaptics._();

  /// Chip / segment / tab selection.
  static void selection() => _run(HapticFeedback.selectionClick);

  /// Light confirmation (add, extend, undo).
  static void light() => _run(HapticFeedback.lightImpact);

  /// Completing something – the most rewarding tap in the app.
  static void success() => _run(HapticFeedback.mediumImpact);

  /// Destructive or high-impact action (delete, urgent replan).
  static void heavy() => _run(HapticFeedback.heavyImpact);

  static void _run(Future<void> Function() call) {
    try {
      unawaited(call().catchError((Object _) {}));
    } catch (_) {
      // Ignore: unsupported platform.
    }
  }
}
