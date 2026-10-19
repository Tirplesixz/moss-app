import 'package:flutter/material.dart';

import '../theme/moss_motion.dart';

Route<T> mossPageRoute<T>(
  BuildContext context,
  Widget page, {
  Duration duration = const Duration(milliseconds: 380),
  Duration reverseDuration = const Duration(milliseconds: 280),
}) {
  final reduced = MossMotion.reduceMotion(context);
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionDuration: reduced ? Duration.zero : duration,
    reverseTransitionDuration: reduced ? Duration.zero : reverseDuration,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.2, 0.9, 0.25, 1.0),
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
