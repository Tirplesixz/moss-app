import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/moss_motion.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../tasks/domain/block.dart';
import '../../../tasks/domain/task.dart';

/// The "Now" card widget as specified in PLAN.md Section 7.1 and 8.
class NowCard extends StatelessWidget {
  final Block? block;
  final Task? task;
  final double progress;
  final int remainingMinutes;
  final bool isPaused;
  final VoidCallback onComplete;
  final VoidCallback onPause;

  const NowCard({
    super.key,
    required this.block,
    this.task,
    required this.progress,
    required this.remainingMinutes,
    this.isPaused = false,
    required this.onComplete,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;

    if (block == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: MossSpacing.x4,
          vertical: MossSpacing.x5,
        ),
        decoration: BoxDecoration(
          color: components.taskSurface,
          borderRadius: BorderRadius.circular(MossRadii.md),
          border: Border.all(color: components.taskBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: MossIconSizes.lg,
              color: theme.primary,
            ),
            const SizedBox(height: MossSpacing.x2),
            Text(
              'ไม่มีงานที่ต้องทำในขณะนี้',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: MossSpacing.x1),
            Text(
              'พักผ่อนได้สบายใจ หรือเพิ่มงานใหม่ด้านล่าง',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.textMuted),
            ),
          ],
        ),
      );
    }

    final title = block!.title ?? task?.title ?? 'งานปัจจุบัน';
    final timeRange = ThaiDateFormatter.formatTimeRange(
      block!.startAt.toLocal(),
      block!.endAt.toLocal(),
    );
    final remainingText = isPaused
        ? 'พักชั่วคราว'
        : ThaiDateFormatter.formatRemainingTime(remainingMinutes);

    return AnimatedContainer(
      duration: MossMotion.duration(context, MossMotion.standard),
      curve: MossMotion.stateCurve,
      width: double.infinity,
      decoration: BoxDecoration(
        color: components.activeTaskSurface,
        borderRadius: BorderRadius.circular(MossRadii.md),
        border: Border.all(color: components.activeTaskBorder),
      ),
      padding: const EdgeInsets.all(MossSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range and Remaining badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            spacing: MossSpacing.x3,
            runSpacing: MossSpacing.x2,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPaused ? theme.textMuted : theme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: MossSpacing.x2),
                  Text(
                    timeRange,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MossSpacing.x3,
                  vertical: MossSpacing.x1,
                ),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(MossRadii.sm),
                  border: Border.all(color: components.activeTaskBorder),
                ),
                child: Text(
                  remainingText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isPaused ? theme.textMuted : theme.onBackground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MossSpacing.x3),

          // Title
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: MossSpacing.x3),

          // Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(MossRadii.sm),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: theme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPaused ? theme.textMuted : theme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: MossSpacing.x4),

          // Secondary Action Buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions =
                  constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.35;
              final completeButton = OutlinedButton.icon(
                onPressed: onComplete,
                icon: Icon(
                  Icons.check_rounded,
                  size: MossIconSizes.md,
                  color: theme.primary,
                ),
                label: const Text('เสร็จแล้ว'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primary,
                  backgroundColor: theme.surface,
                  side: BorderSide(color: components.activeTaskBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MossRadii.md),
                  ),
                ),
              );
              final pauseButton = OutlinedButton.icon(
                onPressed: onPause,
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.coffee_rounded,
                  size: MossIconSizes.md,
                  color: theme.textSecondary,
                ),
                label: Text(isPaused ? 'ทำต่อ' : 'พัก'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textSecondary,
                  backgroundColor: theme.surface,
                  side: BorderSide(color: theme.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MossRadii.md),
                  ),
                ),
              );
              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    completeButton,
                    const SizedBox(height: MossSpacing.x2),
                    pauseButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: completeButton),
                  const SizedBox(width: MossSpacing.x2),
                  Expanded(child: pauseButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
