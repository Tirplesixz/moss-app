import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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
    final title = block.title ?? task?.title ?? 'ไม่มีชื่อ';
    final timeRange = ThaiDateFormatter.formatTimeRange(
      block.startAt.toLocal(),
      block.endAt.toLocal(),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
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
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.onBackground,
                    ),
                  ),
                ),
                if (block.isFixed || block.locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.nowFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.nowBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          block.isFixed ? 'Fixed' : 'Locked',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Time & Duration
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: theme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '$timeRange (${block.durationMin} นาที)',
                  style: TextStyle(fontSize: 14, color: theme.textSecondary),
                ),
              ],
            ),

            if (task?.deadlineAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: theme.urgentAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'เดดไลน์: ${ThaiDateFormatter.formatTime(task!.deadlineAt!.toLocal())}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.urgentAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),

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
                      ? 'ปลดล็อคเวลา (ให้ขยับอัตโนมัติได้)'
                      : 'ล็อคเวลานี้ (ไม่ให้ตารางขยับ)',
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
