import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/block.dart';
import '../../domain/task.dart';

enum BlockAction { complete, toggleLock, edit, delete }

/// Action sheet displayed when tapping a block on the timeline.
class BlockDetailSheet extends StatelessWidget {
  final Block block;
  final Task? task;

  const BlockDetailSheet({super.key, required this.block, this.task});

  static Future<BlockAction?> show(
    BuildContext context, {
    required Block block,
    Task? task,
  }) {
    return showModalBottomSheet<BlockAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlockDetailSheet(block: block, task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    final title = block.title ?? task?.title ?? 'ไม่มีชื่อ';
    final timeRange = ThaiDateFormatter.formatTimeRange(
      block.startAt.toLocal(),
      block.endAt.toLocal(),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MossRadii.lg),
        ),
      ),
      padding: EdgeInsets.only(
        left: MossSpacing.x5,
        right: MossSpacing.x5,
        top: MossSpacing.x4,
        bottom: MediaQuery.of(context).padding.bottom + MossSpacing.x4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: MossSpacing.x4),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (block.isFixed || block.locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MossSpacing.x2,
                      vertical: MossSpacing.x1,
                    ),
                    decoration: BoxDecoration(
                      color: components.fixedTaskSurface,
                      borderRadius: BorderRadius.circular(MossRadii.sm),
                      border: Border.all(color: components.fixedTaskBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: MossIconSizes.sm,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: MossSpacing.x1),
                        Text(
                          block.isFixed ? 'เวลาตายตัว' : 'ล็อกเวลา',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MossSpacing.x2),

            // Time & Duration
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: MossIconSizes.sm,
                  color: theme.textMuted,
                ),
                const SizedBox(width: MossSpacing.x2),
                Text(
                  '$timeRange (${block.durationMin} นาที)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),

            if (task?.deadlineAt != null) ...[
              const SizedBox(height: MossSpacing.x2),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: MossIconSizes.sm,
                    color: theme.urgentAccent,
                  ),
                  const SizedBox(width: MossSpacing.x2),
                  Text(
                    'กำหนดส่ง: ${ThaiDateFormatter.formatTime(task!.deadlineAt!.toLocal())}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.urgentAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: MossSpacing.x5),
            const Divider(height: 1),
            const SizedBox(height: MossSpacing.x3),

            // Action Buttons
            ListTile(
              leading: Icon(
                Icons.check_circle_outline_rounded,
                color: theme.primary,
              ),
              title: Text(
                'ทำเสร็จแล้ว',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.onBackground,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.pop(context, BlockAction.complete),
            ),

            if (!block.isFixed)
              ListTile(
                leading: Icon(
                  block.locked
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  color: theme.textSecondary,
                ),
                title: Text(
                  block.locked
                      ? 'ปลดล็อกเวลา (ให้ขยับอัตโนมัติได้)'
                      : 'ล็อกเวลานี้ (ไม่ให้ตารางขยับ)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.onBackground,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.pop(context, BlockAction.toggleLock),
              ),

            ListTile(
              leading: Icon(Icons.edit_outlined, color: theme.textSecondary),
              title: Text(
                'แก้ไขข้อมูล',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.onBackground,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.pop(context, BlockAction.edit),
            ),

            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: theme.urgentAccent,
              ),
              title: Text(
                'ลบงานนี้',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.urgentAccent,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.pop(context, BlockAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
