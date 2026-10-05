import 'package:flutter/foundation.dart';
import '../../tasks/domain/block.dart';
import '../../tasks/domain/task.dart';

/// Abstract item on the Today timeline.
@immutable
sealed class TodayTimelineItem {
  const TodayTimelineItem();
}

/// A scheduled block (task or fixed event) on the timeline.
class TimelineBlockItem extends TodayTimelineItem {
  final Block block;
  final Task? task;

  const TimelineBlockItem({required this.block, this.task});

  String get displayTitle => block.title ?? task?.title ?? 'ไม่มีชื่อ';
  bool get isFixed => block.isFixed;
  bool get isLocked => block.locked;
}

/// A collapsed free time gap on the timeline.
class TimelineGapItem extends TodayTimelineItem {
  final DateTime startAt;
  final DateTime endAt;
  final int durationMin;

  const TimelineGapItem({
    required this.startAt,
    required this.endAt,
    required this.durationMin,
  });
}
