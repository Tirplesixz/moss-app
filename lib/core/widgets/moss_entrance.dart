import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/moss_motion.dart';

class MossEntrance extends StatefulWidget {
  const MossEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<MossEntrance> createState() => _MossEntranceState();
}

class _MossEntranceState extends State<MossEntrance> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MossMotion.reduceMotion(context)) {
        setState(() => _visible = true);
        return;
      }
      final cappedIndex = widget.index.clamp(0, 5);
      _timer = Timer(MossMotion.stagger * cappedIndex, () {
        if (mounted) setState(() => _visible = true);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: MossMotion.duration(context, MossMotion.standard),
      curve: MossMotion.enterCurve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.025),
        duration: MossMotion.duration(context, MossMotion.standard),
        curve: MossMotion.enterCurve,
        child: widget.child,
      ),
    );
  }
}
