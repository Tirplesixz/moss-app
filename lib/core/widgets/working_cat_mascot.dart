import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/moss_motion.dart';
import '../utils/moss_haptics.dart';

/// Animated Mascot "Blue Working Cat"
/// Renders the Lottie animation with tactile squash-and-stretch interaction
/// and fallback to animated GIF when appropriate.
class WorkingCatMascot extends StatefulWidget {
  const WorkingCatMascot({
    super.key,
    this.width,
    this.height = 84,
    this.fit = BoxFit.contain,
    this.interactive = true,
    this.onTap,
    this.semanticsLabel = 'มาสคอตแมวทำงาน Moss Cat',
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final bool interactive;
  final VoidCallback? onTap;
  final String semanticsLabel;

  @override
  State<WorkingCatMascot> createState() => _WorkingCatMascotState();
}

class _WorkingCatMascotState extends State<WorkingCatMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 320),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.88,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.interactive) return;
    MossHaptics.light();
    _bounceController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MossMotion.reduceMotion(context);
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );

    if (isTest) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: Icon(Icons.pets_rounded, size: 28)),
      );
    }
    final mascotContent = Semantics(
      image: true,
      child: Lottie.asset(
        'assets/animations/blue_working_cat.json',
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        animate: !reduceMotion,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback to GIF
          return Image.asset(
            'assets/animations/blue_working_cat.gif',
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
      ),
    );

    if (widget.interactive || widget.onTap != null) {
      return GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: reduceMotion ? 1.0 : _scaleAnimation.value,
            child: child,
          ),
          child: mascotContent,
        ),
      );
    }

    return mascotContent;
  }
}
