import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/dashed_line.dart';
import '../../domain/today_item.dart';

/// Section "ต่อจากนี้" displaying compact timeline with collapsed dashed gaps
/// as specified in PLAN.md Section 7.1.
class TimelineSection extends StatelessWidget {
  final List<TodayTimelineItem> items;
  final bool hasMoreThan4;
  final bool isShowingAll;
  final int totalCount;
  final VoidCallback onToggleShowAll;
  final ValueChanged<TimelineBlockItem>? onTapBlock;

  const TimelineSection({
    super.key,
    required this.items,
    required this.hasMoreThan4,
    required this.isShowingAll,
    required this.totalCount,
    required this.onToggleShowAll,
    this.onTapBlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ต่อจากนี้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.onBackground,
              ),
            ),
            if (hasMoreThan4)
              TextButton(
                onPressed: onToggleShowAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      isShowingAll
                          ? 'แสดงเฉพาะ 4 งานแรก'
                          : 'ดูทั้งวัน ($totalCount งาน)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                    Icon(
                      isShowingAll
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: theme.primary,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'ไม่มีงานที่จัดตารางไว้หลังจากนี้',
              style: TextStyle(fontSize: 14, color: theme.textMuted),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is TimelineBlockItem) {
                return _buildBlockRow(context, item);
              } else if (item is TimelineGapItem) {
                return _buildCollapsedGapRow(context, item);
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildBlockRow(BuildContext context, TimelineBlockItem item) {
    final theme = context.mossTheme;
    final startLocal = item.block.startAt.toLocal();
    final endLocal = item.block.endAt.toLocal();
    final timeRange = ThaiDateFormatter.formatTimeRange(startLocal, endLocal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTapBlock?.call(item),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: item.isFixed ? theme.nowFill : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: item.isFixed ? theme.primary : theme.nowBorder,
                width: 4,
              ),
              top: BorderSide(color: theme.borderSubtle),
              right: BorderSide(color: theme.borderSubtle),
              bottom: BorderSide(color: theme.borderSubtle),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Time badge
              SizedBox(
                width: 82,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeRange,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.block.durationMin} นาที',
                      style: TextStyle(fontSize: 11, color: theme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Divider
              Container(width: 1, height: 34, color: theme.divider),
              const SizedBox(width: 12),

              // Title & badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.displayTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isFixed || item.isLocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.nowFill.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 11,
                                  color: theme.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item.isFixed ? 'Fixed' : 'Locked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Collapsed free time gap rendered as a single dashed line row
  /// (e.g. "ว่าง 1 ชม. 30 น.") per PLAN.md Section 7.1.
  Widget _buildCollapsedGapRow(BuildContext context, TimelineGapItem gap) {
    final theme = context.mossTheme;
    final gapText = ThaiDateFormatter.formatGap(gap.durationMin);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: DashedLine(color: theme.divider, dashWidth: 4, dashGap: 4),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 12,
                  color: theme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  gapText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DashedLine(color: theme.divider, dashWidth: 4, dashGap: 4),
          ),
        ],
      ),
    );
  }
}
