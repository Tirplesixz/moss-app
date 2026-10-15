import 'package:flutter/material.dart';

import '../theme/moss_motion.dart';

Route<T> mossPageRoute<T>(BuildContext context, Widget page) {
  final reduced = MossMotion.reduceMotion(context);
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionDuration: reduced ? Duration.zero : MossMotion.standard,
    reverseTransitionDuration: reduced ? Duration.zero : MossMotion.exit,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: MossMotion.enterCurve,
        reverseCurve: MossMotion.enterCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
