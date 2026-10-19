import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/moss_task_style.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../today/presentation/today_controller.dart';
import '../../domain/block.dart';
import '../../domain/task.dart';
import '../widgets/pomodoro_timer_sheet.dart';
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
        title: Text('ลบงานนี้?'),
        content: Text('“${task.title}” จะถูกนำออกจากตารางด้วย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.mossTheme.error,
            ),
            child: Text('ลบงาน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    MossHaptics.heavy();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final controller = ref.read(todayControllerProvider.notifier);
    await controller.deleteTask(task);
    showUndoSnackBar(
      messenger,
      message: 'ลบแล้ว: ${task.title}',
      onUndo: controller.undoLastAction,
    );
    navigator.pop();
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
        body: Center(child: Text('ไม่พบงานนี้แล้ว')),
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
        title: Text('รายละเอียดงาน'),
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
            itemBuilder: (_) => [
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
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      MossSpacing.x4,
                      MossSpacing.x5,
                      MossSpacing.x4,
                      MossSpacing.x8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'task_${task.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                ),
                                if (task.projectName?.trim().isNotEmpty ==
                                    true) ...[
                                  SizedBox(height: MossSpacing.x3),
                                  _ProjectBadge(name: task.projectName!),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: MossSpacing.x5),
                        _DetailsCard(task: task),
                        if (!isDone) ...[
                          SizedBox(height: MossSpacing.x4),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2C1B35), Color(0xFF1E2330)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(0xFFE55745).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  MossHaptics.selection();
                                  PomodoroTimerSheet.show(
                                    context,
                                    task: task,
                                    onTaskComplete: (t) => ref
                                        .read(todayControllerProvider.notifier)
                                        .completeTask(t),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFFE55745,
                                          ).withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '🍅',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'เริ่มโหมดโฟกัส (Pomodoro)',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'จับเวลา 25 นาที โฟกัสทำงานนี้ให้เสร็จ',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.72),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.72),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (task.checklist.isNotEmpty) ...[
                          SizedBox(height: MossSpacing.x6),
                          _ChecklistSection(
                            task: task,
                            enabled: !isDone,
                            onChanged: (items) => ref
                                .read(todayControllerProvider.notifier)
                                .updateChecklist(task, items),
                          ),
                        ],
                        SizedBox(height: MossSpacing.x6),
                        Text(
                          'จัดเวลา',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: MossSpacing.x3),
                        _ScheduleCard(block: scheduledBlock),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  child: child,
                                ),
                              ),
                          child: isDone
                              ? Container(
                                  key: ValueKey('done_banner'),
                                  margin: EdgeInsets.only(top: MossSpacing.x5),
                                  width: double.infinity,
                                  padding: EdgeInsets.all(MossSpacing.x4),
                                  decoration: BoxDecoration(
                                    color:
                                        context.mossComponents.internalSurface,
                                    borderRadius: BorderRadius.circular(
                                      MossRadii.lg,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: theme.success,
                                      ),
                                      SizedBox(width: MossSpacing.x3),
                                      Expanded(
                                        child: Text('งานนี้ทำเสร็จแล้ว'),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox.shrink(
                                  key: ValueKey('empty_done_banner'),
                                ),
                        ),
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
                      minimum: EdgeInsets.all(MossSpacing.x4),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                MossHaptics.success();
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                final controller = ref.read(
                                  todayControllerProvider.notifier,
                                );
                                await controller.completeTask(task);
                                showUndoSnackBar(
                                  messenger,
                                  message: 'ทำเสร็จแล้ว: ${task.title}',
                                  onUndo: controller.undoLastAction,
                                );
                                navigator.pop();
                              },
                              child: Text('ทำเสร็จแล้ว'),
                            ),
                          ),
                          SizedBox(width: MossSpacing.x2),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _edit(context, ref, task),
                              child: Text('แก้ไข'),
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
    final pc = MossProjectColors.of(context, name);
    return Container(
      constraints: BoxConstraints(maxWidth: 240),
      padding: EdgeInsets.symmetric(
        horizontal: MossSpacing.x3,
        vertical: MossSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: pc.surface,
        borderRadius: BorderRadius.circular(MossRadii.md),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: pc.accent),
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
          Divider(),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'เวลาที่ใช้',
            value: '${task.durationMin} นาที',
          ),
          Divider(),
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
      padding: EdgeInsets.symmetric(
        horizontal: MossSpacing.x4,
        vertical: MossSpacing.x3,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.textMuted, size: MossIconSizes.md),
          SizedBox(width: MossSpacing.x3),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ),
          SizedBox(width: MossSpacing.x3),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? theme.onBackground,
              ),
            ),
          ),
          SizedBox(width: MossSpacing.x1),
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
      padding: EdgeInsets.all(MossSpacing.x4),
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
          SizedBox(width: MossSpacing.x3),
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
                SizedBox(height: MossSpacing.x1),
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
    if (target == today.add(Duration(days: 1))) return 'พรุ่งนี้';
    return '${date.day}/${date.month}/${date.year + 543}';
  }
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({
    required this.task,
    required this.enabled,
    required this.onChanged,
  });

  final Task task;
  final bool enabled;
  final void Function(List<ChecklistItem> items) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final total = task.checklist.length;
    final done = task.checklistDone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'รายการย่อย',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '$done/$total',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
        SizedBox(height: MossSpacing.x2),
        ClipRRect(
          borderRadius: BorderRadius.circular(MossRadii.full),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 6,
            backgroundColor: theme.surfaceMuted,
            color: theme.success,
          ),
        ),
        SizedBox(height: MossSpacing.x3),
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(MossRadii.lg),
            border: Border.all(color: theme.borderSubtle),
          ),
          child: Column(
            children: [
              for (final item in task.checklist)
                CheckboxListTile(
                  value: item.done,
                  onChanged: enabled
                      ? (value) {
                          MossHaptics.selection();
                          onChanged([
                            for (final c in task.checklist)
                              c.id == item.id
                                  ? c.copyWith(done: value ?? false)
                                  : c,
                          ]);
                        }
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    item.title,
                    style: TextStyle(
                      decoration: item.done ? TextDecoration.lineThrough : null,
                      color: item.done ? theme.textMuted : theme.onBackground,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
