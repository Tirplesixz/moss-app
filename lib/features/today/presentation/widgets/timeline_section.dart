import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/moss_motion.dart';
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
            Text('ต่อจากนี้', style: Theme.of(context).textTheme.titleLarge),
            if (hasMoreThan4)
              TextButton(
                onPressed: onToggleShowAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MossSpacing.x1,
                  ),
                  minimumSize: const Size(48, 48),
                ),
                child: Row(
                  children: [
                    Text(
                      isShowingAll
                          ? 'แสดงเฉพาะ 4 งานแรก'
                          : 'ดูทั้งวัน ($totalCount งาน)',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: theme.primary),
                    ),
                    AnimatedRotation(
                      turns: isShowingAll ? 0.5 : 0,
                      duration: MossMotion.duration(
                        context,
                        MossMotion.standard,
                      ),
                      curve: MossMotion.stateCurve,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: MossIconSizes.md,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: MossSpacing.x2),

        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: MossSpacing.x6),
            alignment: Alignment.center,
            child: Text(
              'ไม่มีงานที่จัดตารางไว้หลังจากนี้',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.textMuted),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MossSpacing.x2),
            itemBuilder: (context, index) {
              final item = items[index];
              final child = switch (item) {
                TimelineBlockItem() => _buildBlockRow(context, item),
                TimelineGapItem() => _buildCollapsedGapRow(context, item),
              };
              final itemKey = switch (item) {
                TimelineBlockItem() => 'block-${item.block.id}',
                TimelineGapItem() =>
                  'gap-${item.startAt.millisecondsSinceEpoch}',
              };
              return _AnimatedTimelineEntry(
                key: ValueKey(itemKey),
                index: index,
                child: child,
              );
            },
          ),
      ],
    );
  }

  Widget _buildBlockRow(BuildContext context, TimelineBlockItem item) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    final startLocal = item.block.startAt.toLocal();
    final endLocal = item.block.endAt.toLocal();
    final timeRange = ThaiDateFormatter.formatTimeRange(
      startLocal,
      endLocal,
    ).replaceFirst(' น.', '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTapBlock?.call(item),
        borderRadius: BorderRadius.circular(MossRadii.md),
        child: Container(
          padding: const EdgeInsets.all(MossSpacing.x3),
          decoration: BoxDecoration(
            color: item.isFixed
                ? components.fixedTaskSurface
                : components.taskSurface,
            borderRadius: BorderRadius.circular(MossRadii.md),
            border: Border.all(
              color: item.isFixed
                  ? components.fixedTaskBorder
                  : components.taskBorder,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final stacked = constraints.maxWidth < 360 || textScale > 1.35;
              final badge = item.isFixed || item.isLocked
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MossSpacing.x2,
                        vertical: MossSpacing.x1,
                      ),
                      decoration: BoxDecoration(
                        color: components.activeTaskSurface,
                        borderRadius: BorderRadius.circular(MossRadii.sm),
                        border: Border.all(color: components.activeTaskBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: MossIconSizes.sm,
                            color: theme.textSecondary,
                          ),
                          const SizedBox(width: MossSpacing.x1),
                          Text(
                            item.isFixed ? 'เวลาตายตัว' : 'ล็อกเวลา',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    )
                  : null;
              final title = Text(
                item.displayTitle,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: stacked ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              );
              final meta = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeRange,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: theme.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                  const SizedBox(height: MossSpacing.x1),
                  Text(
                    '${item.block.durationMin} นาที',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: theme.textMuted),
                  ),
                ],
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (badge != null) ...[
                      const SizedBox(height: MossSpacing.x2),
                      badge,
                    ],
                    const SizedBox(height: MossSpacing.x3),
                    meta,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 104, child: meta),
                  const SizedBox(width: MossSpacing.x2),
                  Container(width: 1, height: 40, color: theme.divider),
                  const SizedBox(width: MossSpacing.x3),
                  Expanded(child: title),
                  if (badge != null) ...[
                    const SizedBox(width: MossSpacing.x2),
                    badge,
                  ],
                ],
              );
            },
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
      padding: const EdgeInsets.symmetric(vertical: MossSpacing.x1),
      child: Row(
        children: [
          Expanded(
            child: DashedLine(
              color: theme.divider,
              dashWidth: MossSpacing.x1,
              dashGap: MossSpacing.x1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MossSpacing.x3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: MossIconSizes.sm,
                  color: theme.textMuted,
                ),
                const SizedBox(width: MossSpacing.x1),
                Text(
                  gapText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: theme.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: DashedLine(
              color: theme.divider,
              dashWidth: MossSpacing.x1,
              dashGap: MossSpacing.x1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTimelineEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedTimelineEntry({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedTimelineEntry> createState() => _AnimatedTimelineEntryState();
}

class _AnimatedTimelineEntryState extends State<_AnimatedTimelineEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MossMotion.emphasis,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: MossMotion.enterCurve,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_opacity);
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final delay = MossMotion.stagger * widget.index.clamp(0, 6);
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
