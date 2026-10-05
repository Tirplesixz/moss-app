import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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

    if (block == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 26,
              color: theme.primary,
            ),
            const SizedBox(height: 7),
            Text(
              'ไม่มีงานที่ต้องทำในขณะนี้',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'พักผ่อนได้สบายใจ หรือเพิ่มงานใหม่ด้านล่าง',
              style: TextStyle(fontSize: 13, color: theme.textMuted),
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.nowFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.nowBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range and Remaining badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const SizedBox(width: 8),
                  Text(
                    timeRange,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.cardBackground.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: theme.nowBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  remainingText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPaused ? theme.textMuted : theme.onBackground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.onBackground,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: theme.cardBackground.withValues(alpha: 0.7),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPaused ? theme.textMuted : theme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Secondary Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: theme.primary,
                  ),
                  label: Text(
                    'เสร็จแล้ว',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.cardBackground.withValues(
                      alpha: 0.9,
                    ),
                    side: BorderSide(
                      color: theme.nowBorder.withValues(alpha: 0.8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPause,
                  icon: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.coffee_rounded,
                    size: 18,
                    color: theme.textSecondary,
                  ),
                  label: Text(
                    isPaused ? 'ทำต่อ' : 'พัก',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.cardBackground.withValues(
                      alpha: 0.9,
                    ),
                    side: BorderSide(color: theme.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
