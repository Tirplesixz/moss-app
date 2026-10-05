import 'package:flutter/foundation.dart';

import '../../../core/scheduler/scheduler.dart';
import '../../tasks/domain/block.dart';
import '../../tasks/domain/task.dart';
import '../domain/today_item.dart';

@immutable
class TodayState {
  final DateTime currentDate;
  final bool isLoading;
  final String? errorMessage;
  final Block? nowBlock;
  final Task? nowTask;
  final double nowProgress;
  final int nowRemainingMinutes;
  final List<String> doneItems;
  final List<TodayTimelineItem> timelineItems;
  final List<Task> overflowTasks;
  final UrgentScheduleResult? urgentProposal;
  final bool canUndo;
  final bool showAllUpcoming;
  final bool isPaused;

  const TodayState({
    required this.currentDate,
    this.isLoading = false,
    this.errorMessage,
    this.nowBlock,
    this.nowTask,
    this.nowProgress = 0,
    this.nowRemainingMinutes = 0,
    this.doneItems = const [],
    this.timelineItems = const [],
    this.overflowTasks = const [],
    this.urgentProposal,
    this.canUndo = false,
    this.showAllUpcoming = false,
    this.isPaused = false,
  });

  int get upcomingBlocksCount =>
      timelineItems.whereType<TimelineBlockItem>().length;

  bool get hasMoreThan4Upcoming => upcomingBlocksCount > 4;

  List<TodayTimelineItem> get visibleTimelineItems {
    if (showAllUpcoming || !hasMoreThan4Upcoming) return timelineItems;
    var blockCount = 0;
    final visible = <TodayTimelineItem>[];
    for (final item in timelineItems) {
      if (item is TimelineBlockItem) {
        if (blockCount >= 4) break;
        blockCount++;
        visible.add(item);
      } else if (item is TimelineGapItem) {
        if (blockCount >= 4) break;
        visible.add(item);
      }
    }
    return visible;
  }

  TodayState copyWith({
    DateTime? currentDate,
    bool? isLoading,
    String? Function()? errorMessage,
    Block? Function()? nowBlock,
    Task? Function()? nowTask,
    double? nowProgress,
    int? nowRemainingMinutes,
    List<String>? doneItems,
    List<TodayTimelineItem>? timelineItems,
    List<Task>? overflowTasks,
    UrgentScheduleResult? Function()? urgentProposal,
    bool? canUndo,
    bool? showAllUpcoming,
    bool? isPaused,
  }) {
    return TodayState(
      currentDate: currentDate ?? this.currentDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      nowBlock: nowBlock != null ? nowBlock() : this.nowBlock,
      nowTask: nowTask != null ? nowTask() : this.nowTask,
      nowProgress: nowProgress ?? this.nowProgress,
      nowRemainingMinutes: nowRemainingMinutes ?? this.nowRemainingMinutes,
      doneItems: doneItems ?? this.doneItems,
      timelineItems: timelineItems ?? this.timelineItems,
      overflowTasks: overflowTasks ?? this.overflowTasks,
      urgentProposal: urgentProposal != null
          ? urgentProposal()
          : this.urgentProposal,
      canUndo: canUndo ?? this.canUndo,
      showAllUpcoming: showAllUpcoming ?? this.showAllUpcoming,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
