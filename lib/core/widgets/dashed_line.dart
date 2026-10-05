import 'package:flutter/material.dart';

/// A custom dashed line widget for drawing collapsed free time gaps.
class DashedLine extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashGap;

  const DashedLine({
    super.key,
    this.height = 1,
    required this.color,
    this.dashWidth = 5.0,
    this.dashGap = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashGap)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
