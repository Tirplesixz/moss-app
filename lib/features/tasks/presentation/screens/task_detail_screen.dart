import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../today/presentation/today_controller.dart';
import '../../domain/block.dart';
import '../../domain/task.dart';
import 'add_task_screen.dart';

enum _TaskMenuAction { edit, delete }

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId, this.initialTask});

  final String taskId;
  final Task? initialTask;

  Future<void> _edit(BuildContext context, WidgetRef ref, Task task) async {
    final result = await AddTaskScreen.show(context, editTask: task);
    if (result is Task) {
      await ref.read(todayControllerProvider.notifier).updateTask(result);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบงานนี้?'),
        content: Text('“${task.title}” จะถูกนำออกจากตารางด้วย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.mossTheme.error,
            ),
            child: const Text('ลบงาน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(todayControllerProvider.notifier).deleteTask(task);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayControllerProvider);
    final task = state.allTasks.cast<Task?>().firstWhere(
      (item) => item?.id == taskId,
      orElse: () => initialTask,
    );
    final theme = context.mossTheme;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('ไม่พบงานนี้แล้ว')),
      );
    }

    final scheduledBlock = state.allBlocks.cast<Block?>().firstWhere(
      (block) => block?.taskId == task.id,
      orElse: () => null,
    );
    final isDone = task.status == TaskStatus.done;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('รายละเอียดงาน'),
        actions: [
          PopupMenuButton<_TaskMenuAction>(
            tooltip: 'ตัวเลือกเพิ่มเติม',
            onSelected: (action) {
              switch (action) {
                case _TaskMenuAction.edit:
                  _edit(context, ref, task);
                  break;
                case _TaskMenuAction.delete:
                  _delete(context, ref, task);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _TaskMenuAction.edit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('แก้ไข'),
                ),
              ),
              PopupMenuItem(
                value: _TaskMenuAction.delete,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('ลบงาน'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      MossSpacing.x4,
                      MossSpacing.x5,
                      MossSpacing.x4,
                      MossSpacing.x8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (task.projectName?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: MossSpacing.x3),
                          _ProjectBadge(name: task.projectName!),
                        ],
                        const SizedBox(height: MossSpacing.x5),
                        _DetailsCard(task: task),
                        const SizedBox(height: MossSpacing.x6),
                        Text(
                          'จัดเวลา',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: MossSpacing.x3),
                        _ScheduleCard(block: scheduledBlock),
                        if (isDone) ...[
                          const SizedBox(height: MossSpacing.x5),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(MossSpacing.x4),
                            decoration: BoxDecoration(
                              color: context.mossComponents.internalSurface,
                              borderRadius: BorderRadius.circular(MossRadii.lg),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.success,
                                ),
                                const SizedBox(width: MossSpacing.x3),
                                const Expanded(
                                  child: Text('งานนี้ทำเสร็จแล้ว'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isDone)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      border: Border(top: BorderSide(color: theme.divider)),
                    ),
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.all(MossSpacing.x4),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await ref
                                    .read(todayControllerProvider.notifier)
                                    .completeTask(task);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('ทำเสร็จแล้ว'),
                            ),
                          ),
                          const SizedBox(width: MossSpacing.x2),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _edit(context, ref, task),
                              child: const Text('แก้ไข'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectBadge extends StatelessWidget {
  const _ProjectBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final components = context.mossComponents;
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(
        horizontal: MossSpacing.x3,
        vertical: MossSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: components.projectSurface,
        borderRadius: BorderRadius.circular(MossRadii.md),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: components.projectAccent),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'วันครบกำหนด',
            value: task.deadlineAt == null
                ? 'ไม่มีกำหนดส่ง'
                : _formatDate(task.deadlineAt!.toLocal()),
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'เวลาที่ใช้',
            value: '${task.durationMin} นาที',
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.flag_outlined,
            label: 'ความสำคัญ',
            value: switch (task.priority) {
              3 => 'สูง',
              1 => 'ต่ำ',
              _ => 'ปกติ',
            },
            valueColor: task.priority == 3 ? theme.error : null,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year + 543}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MossSpacing.x4,
        vertical: MossSpacing.x3,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.textMuted, size: MossIconSizes.md),
          const SizedBox(width: MossSpacing.x3),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ),
          const SizedBox(width: MossSpacing.x3),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? theme.onBackground,
              ),
            ),
          ),
          const SizedBox(width: MossSpacing.x1),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.textMuted,
            size: MossIconSizes.md,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.block});

  final Block? block;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MossSpacing.x4),
      decoration: BoxDecoration(
        color: block == null ? theme.surface : components.projectSurface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(
          color: block == null ? theme.borderSubtle : components.projectAccent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            block == null ? Icons.event_busy_outlined : Icons.schedule_rounded,
            color: block == null ? theme.textMuted : components.projectAccent,
          ),
          const SizedBox(width: MossSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block == null
                      ? 'ยังไม่ได้จัดเวลา'
                      : ThaiDateFormatter.formatTimeRange(
                          block!.startAt.toLocal(),
                          block!.endAt.toLocal(),
                        ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MossSpacing.x1),
                Text(
                  block == null
                      ? 'กดจัดลงตารางจากหน้างานเข้า'
                      : _dateLabel(block!.startAt.toLocal()),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: theme.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.textMuted),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'วันนี้';
    if (target == today.add(const Duration(days: 1))) return 'พรุ่งนี้';
    return '${date.day}/${date.month}/${date.year + 543}';
  }
}
