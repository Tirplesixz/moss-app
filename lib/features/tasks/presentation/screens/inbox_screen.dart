import 'package:flutter/material.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/moss_task_style.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../../core/widgets/moss_entrance.dart';
import '../../../../core/validation/input_limits.dart';
import '../../domain/task.dart';

enum InboxFilter { all, unscheduled }

class InboxScreen extends StatefulWidget {
  const InboxScreen({
    super.key,
    required this.tasks,
    required this.unscheduledTaskIds,
    required this.isLoading,
    required this.onQuickAdd,
    required this.onAddTask,
    required this.onOpenTask,
    required this.onCompleteTask,
    required this.onReschedule,
  });

  final List<Task> tasks;
  final Set<String> unscheduledTaskIds;
  final bool isLoading;
  final Future<void> Function(String title) onQuickAdd;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onOpenTask;
  final Future<void> Function(Task task) onCompleteTask;
  final Future<void> Function() onReschedule;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  InboxFilter _filter = InboxFilter.all;
  bool _submitting = false;
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    MossHaptics.selection();
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onQuickAdd(value);
      _controller.clear();
      _focusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final todoTasks = widget.tasks
        .where((task) => task.status == TaskStatus.todo)
        .toList();
    final filtered = _filter == InboxFilter.all
        ? todoTasks
        : todoTasks
              .where((task) => widget.unscheduledTaskIds.contains(task.id))
              .toList();
    final q = _query.trim().toLowerCase();
    final visibleTasks = q.isEmpty
        ? filtered
        : filtered
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    (t.projectName?.toLowerCase().contains(q) ?? false),
              )
              .toList();

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          MossSpacing.x4,
                          MossSpacing.x6,
                          MossSpacing.x4,
                          MossSpacing.x3,
                        ),
                        sliver: SliverList.list(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'งานเข้า',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.displaySmall,
                                      ),
                                      const SizedBox(height: MossSpacing.x1),
                                      Text(
                                        'จดไว้ก่อน แล้วให้ Moss ช่วยจัดเวลา',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: theme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: _searching
                                      ? 'ปิดการค้นหา'
                                      : 'ค้นหางาน',
                                  onPressed: _toggleSearch,
                                  icon: Icon(
                                    _searching
                                        ? Icons.search_off_rounded
                                        : Icons.search_rounded,
                                  ),
                                ),
                                IconButton.filledTonal(
                                  tooltip: 'เพิ่มงานแบบละเอียด',
                                  onPressed: widget.onAddTask,
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                            if (_searching) ...[
                              const SizedBox(height: MossSpacing.x3),
                              TextField(
                                controller: _searchController,
                                maxLength: InputLimits.taskTitle,
                                buildCounter:
                                    (
                                      _, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) => null,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                onChanged: (v) => setState(() => _query = v),
                                decoration: InputDecoration(
                                  hintText: 'ค้นหาชื่องานหรือโปรเจกต์…',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'ล้างคำค้นหา',
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _query = '');
                                          },
                                        ),
                                ),
                              ),
                            ],
                            const SizedBox(height: MossSpacing.x5),
                            TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              textInputAction: TextInputAction.done,
                              maxLength: InputLimits.taskTitle,
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'เพิ่มงานที่นึกออก…',
                                counterText: '',
                                prefixIcon: const Icon(Icons.add_rounded),
                                suffixIcon: _submitting
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        tooltip: 'เพิ่มงาน',
                                        onPressed: _submit,
                                        icon: const Icon(
                                          Icons.arrow_upward_rounded,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: MossSpacing.x4),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<InboxFilter>(
                                showSelectedIcon: false,
                                segments: [
                                  ButtonSegment(
                                    value: InboxFilter.all,
                                    label: Text(
                                      'ทั้งหมด (${todoTasks.length})',
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: InboxFilter.unscheduled,
                                    label: Text(
                                      'ยังไม่จัดเวลา (${widget.unscheduledTaskIds.length})',
                                    ),
                                  ),
                                ],
                                selected: {_filter},
                                onSelectionChanged: (selection) {
                                  MossHaptics.selection();
                                  setState(() => _filter = selection.first);
                                },
                              ),
                            ),
                            const SizedBox(height: MossSpacing.x4),
                          ],
                        ),
                      ),
                      if (widget.isLoading && visibleTasks.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (visibleTasks.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _InboxEmptyState(
                            filter: _filter,
                            query: _query.trim(),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            MossSpacing.x4,
                            0,
                            MossSpacing.x4,
                            MossSpacing.x12,
                          ),
                          sliver: SliverList.separated(
                            itemCount: visibleTasks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: MossSpacing.x3),
                            itemBuilder: (context, index) {
                              final task = visibleTasks[index];
                              return MossEntrance(
                                index: index,
                                child: _InboxTaskCard(
                                  task: task,
                                  isUnscheduled: widget.unscheduledTaskIds
                                      .contains(task.id),
                                  onTap: () => widget.onOpenTask(task),
                                  onComplete: () => widget.onCompleteTask(task),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border(top: BorderSide(color: theme.divider)),
                  ),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.all(MossSpacing.x4),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.isLoading
                            ? null
                            : widget.onReschedule,
                        icon: widget.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.calendar_month_outlined),
                        label: const Text('จัดลงตาราง'),
                      ),
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

class _InboxTaskCard extends StatelessWidget {
  const _InboxTaskCard({
    required this.task,
    required this.isUnscheduled,
    required this.onTap,
    required this.onComplete,
  });

  final Task task;
  final bool isUnscheduled;
  final VoidCallback onTap;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final hasProject = task.projectName?.trim().isNotEmpty == true;

    return Material(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MossRadii.lg),
        side: BorderSide(color: theme.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(MossSpacing.x4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: 'ทำ ${task.title} ให้เสร็จ',
                child: IconButton(
                  tooltip: 'ทำเสร็จแล้ว',
                  onPressed: () => onComplete(),
                  icon: const Icon(Icons.circle_outlined),
                  color: theme.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
              const SizedBox(width: MossSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (hasProject) ...[
                          const SizedBox(width: MossSpacing.x2),
                          Builder(
                            builder: (context) {
                              final pc = MossProjectColors.of(
                                context,
                                task.projectName!,
                              );
                              return Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: MossSpacing.x2,
                                  vertical: MossSpacing.x1,
                                ),
                                decoration: BoxDecoration(
                                  color: pc.surface,
                                  borderRadius: BorderRadius.circular(
                                    MossRadii.sm,
                                  ),
                                ),
                                child: Text(
                                  task.projectName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: pc.accent),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: MossSpacing.x2),
                    Wrap(
                      spacing: MossSpacing.x3,
                      runSpacing: MossSpacing.x1,
                      children: [
                        _TaskMeta(
                          icon: Icons.calendar_today_outlined,
                          label: task.deadlineAt == null
                              ? 'ไม่มีกำหนดส่ง'
                              : _formatDeadline(task.deadlineAt!.toLocal()),
                          color: task.deadlineAt == null
                              ? theme.textMuted
                              : theme.info,
                        ),
                        _TaskMeta(
                          icon: Icons.schedule_outlined,
                          label: '${task.durationMin} นาที',
                          color: theme.textMuted,
                        ),
                        if (isUnscheduled)
                          _TaskMeta(
                            icon: Icons.hourglass_empty_rounded,
                            label: 'รอจัดเวลา',
                            color: theme.warning,
                          ),
                        if (task.priority != MossPriority.normal)
                          PriorityBadge(priority: task.priority),
                        if (task.checklist.isNotEmpty)
                          _TaskMeta(
                            icon: Icons.checklist_rounded,
                            label:
                                '${task.checklistDone}/${task.checklist.length}',
                            color: theme.textMuted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MossSpacing.x1),
              Icon(Icons.chevron_right_rounded, color: theme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDeadline(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'วันนี้';
    if (target == today.add(const Duration(days: 1))) return 'พรุ่งนี้';
    return '${date.day}/${date.month}/${date.year + 543}';
  }
}

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: MossIconSizes.sm, color: color),
        const SizedBox(width: MossSpacing.x1),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _InboxEmptyState extends StatelessWidget {
  const _InboxEmptyState({required this.filter, this.query = ''});

  final InboxFilter filter;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    if (query.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MossSpacing.x8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 44, color: theme.textMuted),
              const SizedBox(height: MossSpacing.x3),
              Text(
                'ไม่พบงานที่ตรงกับ "$query"',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MossSpacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter == InboxFilter.all
                  ? Icons.task_alt_rounded
                  : Icons.auto_awesome_rounded,
              size: 44,
              color: theme.primary,
            ),
            const SizedBox(height: MossSpacing.x3),
            Text(
              filter == InboxFilter.all
                  ? 'งานเข้าว่างแล้ว'
                  : 'ทุกงานมีเวลาแล้ว',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MossSpacing.x2),
            Text(
              filter == InboxFilter.all
                  ? 'เพิ่มงานใหม่ได้จากช่องด้านบน'
                  : 'Moss จัดงานทั้งหมดลงตารางเรียบร้อย',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
