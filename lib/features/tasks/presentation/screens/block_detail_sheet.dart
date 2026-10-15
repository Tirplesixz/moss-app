import 'package:flutter/material.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/moss_motion.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../domain/block.dart';
import '../../domain/task.dart';

enum BlockAction { complete, toggleLock, edit, delete }

/// Focused action sheet displayed when tapping an agenda block.
class BlockDetailSheet extends StatelessWidget {
  const BlockDetailSheet({super.key, required this.block, this.task});

  final Block block;
  final Task? task;

  static Future<BlockAction?> show(
    BuildContext context, {
    required Block block,
    Task? task,
  }) {
    final reducedMotion = MossMotion.reduceMotion(context);
    return showModalBottomSheet<BlockAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      sheetAnimationStyle: AnimationStyle(
        duration: reducedMotion ? Duration.zero : MossMotion.emphasis,
        reverseDuration: reducedMotion ? Duration.zero : MossMotion.exit,
      ),
      builder: (context) => BlockDetailSheet(block: block, task: task),
    );
  }

  Future<void> _requestDelete(BuildContext context) async {
    final theme = context.mossTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: theme.error),
        title: const Text('ลบงานนี้?'),
        content: const Text(
          'งานและช่วงเวลานี้จะถูกนำออกจากตาราง การดำเนินการนี้ย้อนกลับไม่ได้',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: theme.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบงาน'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context, BlockAction.delete);
    }
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

    return Material(
      color: theme.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MossRadii.xl)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MossSpacing.x5,
            MossSpacing.x3,
            MossSpacing.x5,
            MossSpacing.x5,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.borderSubtle,
                        borderRadius: BorderRadius.circular(MossRadii.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: MossSpacing.x3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'รายละเอียดช่วงเวลา',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: theme.textSecondary),
                        ),
                      ),
                      IconButton(
                        tooltip: 'ปิด',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: MossSpacing.x2),
                  _BlockSummaryCard(
                    title: title,
                    timeRange: timeRange,
                    block: block,
                    task: task,
                  ),
                  const SizedBox(height: MossSpacing.x5),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, BlockAction.complete),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('ทำเสร็จแล้ว'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ),
                  const SizedBox(height: MossSpacing.x5),
                  Text(
                    'จัดการงาน',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: MossSpacing.x3),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          constraints.maxWidth < 390 ||
                          MediaQuery.textScalerOf(
                                context,
                              ).scale(MossTypeSizes.body) >
                              20;
                      final edit = _SheetActionCard(
                        icon: Icons.edit_rounded,
                        title: 'แก้ไขข้อมูล',
                        description: 'ชื่อ เวลา และรายละเอียด',
                        iconColor: theme.info,
                        iconSurface: components.customerSurface,
                        onTap: () => Navigator.pop(context, BlockAction.edit),
                      );
                      final lock = _SheetActionCard(
                        icon: block.locked
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                        title: block.locked ? 'ปลดล็อกเวลา' : 'ล็อกเวลานี้',
                        description: block.locked
                            ? 'ให้ Moss จัดเวลาใหม่ได้'
                            : 'ป้องกันตารางขยับอัตโนมัติ',
                        iconColor: components.internalAccent,
                        iconSurface: components.internalSurface,
                        onTap: () =>
                            Navigator.pop(context, BlockAction.toggleLock),
                      );

                      if (stacked || block.isFixed) {
                        return Column(
                          children: [
                            edit,
                            if (!block.isFixed) ...[
                              const SizedBox(height: MossSpacing.x3),
                              lock,
                            ],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: edit),
                          const SizedBox(width: MossSpacing.x3),
                          Expanded(child: lock),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: MossSpacing.x4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _requestDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('ลบงานนี้'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: theme.error,
                        side: BorderSide(
                          color: theme.error.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockSummaryCard extends StatelessWidget {
  const _BlockSummaryCard({
    required this.title,
    required this.timeRange,
    required this.block,
    required this.task,
  });

  final String title;
  final String timeRange;
  final Block block;
  final Task? task;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    final project = task?.projectName?.trim();
    final locked = block.isFixed || block.locked;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MossSpacing.x4),
      decoration: BoxDecoration(
        color: components.projectSurface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(
          color: components.projectAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: components.projectAccent,
                  borderRadius: BorderRadius.circular(MossRadii.md),
                ),
                child: Icon(
                  block.isFixed
                      ? Icons.event_available_rounded
                      : Icons.auto_awesome_rounded,
                  color: theme.onPrimary,
                ),
              ),
              const SizedBox(width: MossSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (project?.isNotEmpty == true) ...[
                      const SizedBox(height: MossSpacing.x1),
                      Text(
                        project!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: components.projectAccent),
                      ),
                    ],
                  ],
                ),
              ),
              if (locked) ...[
                const SizedBox(width: MossSpacing.x2),
                _StatusPill(
                  icon: Icons.lock_rounded,
                  label: block.isFixed ? 'เวลาตายตัว' : 'ล็อกแล้ว',
                ),
              ],
            ],
          ),
          const SizedBox(height: MossSpacing.x4),
          Wrap(
            spacing: MossSpacing.x3,
            runSpacing: MossSpacing.x2,
            children: [
              _SummaryMeta(icon: Icons.schedule_rounded, label: timeRange),
              _SummaryMeta(
                icon: Icons.timelapse_rounded,
                label: '${block.durationMin} นาที',
              ),
              if (task?.deadlineAt != null)
                _SummaryMeta(
                  icon: Icons.flag_rounded,
                  label:
                      'กำหนด ${ThaiDateFormatter.formatTime(task!.deadlineAt!.toLocal())}',
                  color: theme.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final components = context.mossComponents;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MossSpacing.x2,
        vertical: MossSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: components.internalSurface,
        borderRadius: BorderRadius.circular(MossRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: MossIconSizes.sm, color: components.internalAccent),
          const SizedBox(width: MossSpacing.x1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: components.internalAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMeta extends StatelessWidget {
  const _SummaryMeta({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final resolvedColor = color ?? theme.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: MossIconSizes.sm, color: resolvedColor),
        const SizedBox(width: MossSpacing.x1),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: resolvedColor),
        ),
      ],
    );
  }
}

class _SheetActionCard extends StatelessWidget {
  const _SheetActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.iconSurface,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color iconSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Material(
      color: theme.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MossRadii.md),
        side: BorderSide(color: theme.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(MossSpacing.x3),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconSurface,
                  borderRadius: BorderRadius.circular(MossRadii.md),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: MossSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: MossSpacing.x1),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textMuted,
                size: MossIconSizes.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
