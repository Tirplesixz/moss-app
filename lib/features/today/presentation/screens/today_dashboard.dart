import 'package:flutter/material.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/moss_motion.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../../core/widgets/moss_entrance.dart';
import '../../../tasks/domain/block.dart';
import '../../../tasks/domain/task.dart';
import '../../domain/today_item.dart';
import '../today_state.dart';

enum CalendarRange { day, threeDays, month }

class TodayDashboard extends StatefulWidget {
  const TodayDashboard({
    super.key,
    required this.state,
    required this.onAddTask,
    required this.onOpenSettings,
    required this.onOpenBlock,
    required this.onRetry,
  });

  final TodayState state;
  final VoidCallback onAddTask;
  final VoidCallback onOpenSettings;
  final ValueChanged<TimelineBlockItem> onOpenBlock;
  final VoidCallback onRetry;

  @override
  State<TodayDashboard> createState() => _TodayDashboardState();
}

class _TodayDashboardState extends State<TodayDashboard> {
  CalendarRange _range = CalendarRange.day;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.state.currentDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final tasksById = {for (final task in widget.state.allTasks) task.id: task};

    return Scaffold(
      backgroundColor: theme.background,
      floatingActionButton: FloatingActionButton(
        tooltip: 'เพิ่มงาน',
        onPressed: widget.onAddTask,
        backgroundColor: theme.primary,
        foregroundColor: theme.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MossSpacing.x4,
                    MossSpacing.x5,
                    MossSpacing.x4,
                    MossSpacing.x3,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _TodayHeader(
                        selectedDate: _selectedDate,
                        onGoToday: () {
                          setState(() {
                            _selectedDate = widget.state.currentDate;
                            _range = CalendarRange.day;
                          });
                        },
                        onOpenSettings: widget.onOpenSettings,
                      ),
                      const SizedBox(height: MossSpacing.x4),
                      _WeekStrip(
                        selectedDate: _selectedDate,
                        onSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                            _range = CalendarRange.day;
                          });
                        },
                      ),
                      const SizedBox(height: MossSpacing.x3),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<CalendarRange>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: CalendarRange.day,
                              label: Text('วัน'),
                            ),
                            ButtonSegment(
                              value: CalendarRange.threeDays,
                              label: Text('3 วัน'),
                            ),
                            ButtonSegment(
                              value: CalendarRange.month,
                              label: Text('เดือน'),
                            ),
                          ],
                          selected: {_range},
                          onSelectionChanged: (value) {
                            setState(() => _range = value.first);
                          },
                        ),
                      ),
                      const SizedBox(height: MossSpacing.x4),
                      if (widget.state.isLoading)
                        LinearProgressIndicator(
                          minHeight: 2,
                          borderRadius: BorderRadius.circular(MossRadii.full),
                        ),
                      if (widget.state.errorMessage != null) ...[
                        _ErrorCard(
                          message: widget.state.errorMessage!,
                          onRetry: widget.onRetry,
                        ),
                        const SizedBox(height: MossSpacing.x3),
                      ],
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MossSpacing.x4,
                    0,
                    MossSpacing.x4,
                    112,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: MossMotion.duration(
                        context,
                        MossMotion.standard,
                      ),
                      switchInCurve: MossMotion.enterCurve,
                      switchOutCurve: MossMotion.enterCurve,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: switch (_range) {
                        CalendarRange.day => _DayView(
                          key: ValueKey('day-${_dayKey(_selectedDate)}'),
                          date: _selectedDate,
                          blocks: _blocksForDate(
                            widget.state.allBlocks,
                            _selectedDate,
                          ),
                          tasksById: tasksById,
                          onOpenBlock: widget.onOpenBlock,
                        ),
                        CalendarRange.threeDays => _ThreeDayView(
                          key: ValueKey('three-${_dayKey(_selectedDate)}'),
                          startDate: _selectedDate,
                          blocks: widget.state.allBlocks,
                          tasksById: tasksById,
                          onOpenBlock: widget.onOpenBlock,
                        ),
                        CalendarRange.month => _MonthView(
                          key: ValueKey(
                            'month-${_selectedDate.year}-${_selectedDate.month}',
                          ),
                          month: _selectedDate,
                          blocks: widget.state.allBlocks,
                          onSelectDate: (date) {
                            setState(() {
                              _selectedDate = date;
                              _range = CalendarRange.day;
                            });
                          },
                        ),
                      },
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

  static List<Block> _blocksForDate(List<Block> blocks, DateTime date) {
    final result = blocks.where((block) {
      final local = block.startAt.toLocal();
      return local.year == date.year &&
          local.month == date.month &&
          local.day == date.day;
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
    return result;
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({
    required this.selectedDate,
    required this.onGoToday,
    required this.onOpenSettings,
  });

  final DateTime selectedDate;
  final VoidCallback onGoToday;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected == today ? 'วันนี้' : '${selectedDate.day} $_month',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: MossSpacing.x1),
              Text(
                '${ThaiDateFormatter.formatFullDate(selectedDate)} ${selectedDate.year + 543}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'ไปวันนี้',
          onPressed: onGoToday,
          icon: const Icon(Icons.calendar_today_outlined),
        ),
        IconButton(
          tooltip: 'การตั้งค่า',
          onPressed: onOpenSettings,
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }

  String get _month => const [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ][selectedDate.month - 1];
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDate, required this.onSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    final monday = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    const labels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Row(
      children: List.generate(7, (index) {
        final day = monday.add(Duration(days: index));
        final selected = _sameDay(day, selectedDate);
        return Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            label: '${labels[index]} ${day.day}',
            child: InkWell(
              borderRadius: BorderRadius.circular(MossRadii.md),
              onTap: () => onSelected(day),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: MossSpacing.x1),
                child: Column(
                  children: [
                    Text(
                      labels[index],
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? theme.primary : theme.textMuted,
                      ),
                    ),
                    const SizedBox(height: MossSpacing.x1),
                    AnimatedContainer(
                      duration: MossMotion.duration(
                        context,
                        MossMotion.standard,
                      ),
                      curve: MossMotion.stateCurve,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? components.navigationSelectedSurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(MossRadii.md),
                      ),
                      child: Text(
                        '${day.day}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: selected
                                  ? theme.primary
                                  : theme.onBackground,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayView extends StatelessWidget {
  const _DayView({
    super.key,
    required this.date,
    required this.blocks,
    required this.tasksById,
    required this.onOpenBlock,
  });

  final DateTime date;
  final List<Block> blocks;
  final Map<String, Task> tasksById;
  final ValueChanged<TimelineBlockItem> onOpenBlock;

  @override
  Widget build(BuildContext context) {
    final freeMinutes = _freeMinutes(blocks);
    return Column(
      children: [
        _DaySummary(taskCount: blocks.length, freeMinutes: freeMinutes),
        const SizedBox(height: MossSpacing.x4),
        if (blocks.isEmpty)
          const _AgendaEmptyState()
        else
          _AgendaList(
            date: date,
            blocks: blocks,
            tasksById: tasksById,
            onOpenBlock: onOpenBlock,
          ),
      ],
    );
  }

  int _freeMinutes(List<Block> blocks) {
    const workdayMinutes = 9 * 60;
    final occupied = blocks.fold<int>(
      0,
      (total, block) => total + block.durationMin,
    );
    return (workdayMinutes - occupied).clamp(0, workdayMinutes);
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.taskCount, required this.freeMinutes});

  final int taskCount;
  final int freeMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final freeHours = freeMinutes ~/ 60;
    final remaining = freeMinutes % 60;
    final taskSummary = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: theme.success),
        const SizedBox(width: MossSpacing.x2),
        Flexible(
          child: Text(
            'งานวันนี้ $taskCount รายการ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
    final freeSummary = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_outlined,
          color: theme.textSecondary,
          size: MossIconSizes.md,
        ),
        const SizedBox(width: MossSpacing.x2),
        Flexible(
          child: Text(
            'ว่าง $freeHours ชม.${remaining == 0 ? '' : ' $remaining น.'}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MossSpacing.x4,
        vertical: MossSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout =
              constraints.maxWidth < 390 ||
              MediaQuery.textScalerOf(context).scale(MossTypeSizes.body) > 20;
          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                taskSummary,
                const SizedBox(height: MossSpacing.x2),
                freeSummary,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: taskSummary),
              SizedBox(
                height: 24,
                child: VerticalDivider(color: theme.divider),
              ),
              const SizedBox(width: MossSpacing.x2),
              Flexible(child: freeSummary),
            ],
          );
        },
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({
    required this.date,
    required this.blocks,
    required this.tasksById,
    required this.onOpenBlock,
  });

  final DateTime date;
  final List<Block> blocks;
  final Map<String, Task> tasksById;
  final ValueChanged<TimelineBlockItem> onOpenBlock;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final children = <Widget>[];
    var insertedNow = false;

    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      final localStart = block.startAt.toLocal();
      if (isToday && !insertedNow && now.isBefore(localStart)) {
        children.add(_NowLine(now: now));
        insertedNow = true;
      }
      final task = block.taskId == null ? null : tasksById[block.taskId];
      children.add(
        MossEntrance(
          index: index,
          child: _AgendaCard(
            block: block,
            task: task,
            onTap: () =>
                onOpenBlock(TimelineBlockItem(block: block, task: task)),
          ),
        ),
      );
      children.add(const SizedBox(height: MossSpacing.x2));
    }
    if (isToday && !insertedNow) children.add(_NowLine(now: now));

    return Column(children: children);
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.block,
    required this.task,
    required this.onTap,
  });

  final Block block;
  final Task? task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    final (surface, accent, tag) = block.isFixed
        ? (components.internalSurface, components.internalAccent, 'เวลาตายตัว')
        : task?.projectName?.trim().isNotEmpty == true
        ? (
            components.projectSurface,
            components.projectAccent,
            task!.projectName!,
          )
        : (
            components.customerSurface,
            components.customerAccent,
            task?.priority == 3 ? 'สำคัญ' : 'งานทั่วไป',
          );
    final title = block.title ?? task?.title ?? 'ไม่มีชื่อ';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Padding(
            padding: const EdgeInsets.only(top: MossSpacing.x3),
            child: Text(
              _time(block.startAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MossRadii.md),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(MossSpacing.x4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(width: MossSpacing.x2),
                                Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 120,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: MossSpacing.x2,
                                    vertical: MossSpacing.x1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      MossRadii.sm,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: accent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: MossSpacing.x1),
                            Text(
                              ThaiDateFormatter.formatTimeRange(
                                block.startAt.toLocal(),
                                block.endAt.toLocal(),
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: theme.textSecondary),
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
        ),
      ],
    );
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _NowLine extends StatelessWidget {
  const _NowLine({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final label =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MossSpacing.x2),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: theme.error),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Divider(color: theme.error, thickness: 1)),
        ],
      ),
    );
  }
}

class _ThreeDayView extends StatelessWidget {
  const _ThreeDayView({
    super.key,
    required this.startDate,
    required this.blocks,
    required this.tasksById,
    required this.onOpenBlock,
  });

  final DateTime startDate;
  final List<Block> blocks;
  final Map<String, Task> tasksById;
  final ValueChanged<TimelineBlockItem> onOpenBlock;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final width = wide
            ? (constraints.maxWidth - MossSpacing.x4 * 2) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: MossSpacing.x4,
          runSpacing: MossSpacing.x4,
          children: List.generate(3, (index) {
            final date = startDate.add(Duration(days: index));
            final dayBlocks = _TodayDashboardState._blocksForDate(blocks, date);
            return SizedBox(
              width: width,
              child: _CompactDay(
                date: date,
                blocks: dayBlocks,
                tasksById: tasksById,
                onOpenBlock: onOpenBlock,
              ),
            );
          }),
        );
      },
    );
  }
}

class _CompactDay extends StatelessWidget {
  const _CompactDay({
    required this.date,
    required this.blocks,
    required this.tasksById,
    required this.onOpenBlock,
  });

  final DateTime date;
  final List<Block> blocks;
  final Map<String, Task> tasksById;
  final ValueChanged<TimelineBlockItem> onOpenBlock;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Container(
      padding: const EdgeInsets.all(MossSpacing.x4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_weekday(date.weekday)} ${date.day}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: MossSpacing.x3),
          if (blocks.isEmpty)
            Text(
              'ยังไม่มีงาน',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.textMuted),
            )
          else
            ...blocks.take(4).map((block) {
              final task = block.taskId == null
                  ? null
                  : tasksById[block.taskId];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  _AgendaCard._time(block.startAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                title: Text(
                  block.title ?? task?.title ?? 'ไม่มีชื่อ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    onOpenBlock(TimelineBlockItem(block: block, task: task)),
              );
            }),
        ],
      ),
    );
  }

  static String _weekday(int value) =>
      const ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'][value - 1];
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    super.key,
    required this.month,
    required this.blocks,
    required this.onSelectDate,
  });

  final DateTime month;
  final List<Block> blocks;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final totalCells = ((leading + days + 6) ~/ 7) * 7;
    const labels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Container(
      padding: const EdgeInsets.all(MossSpacing.x3),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: labels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: MossSpacing.x2),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: MossSpacing.x1,
              crossAxisSpacing: MossSpacing.x1,
            ),
            itemBuilder: (context, index) {
              final day = index - leading + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              final count = _TodayDashboardState._blocksForDate(
                blocks,
                date,
              ).length;
              return InkWell(
                borderRadius: BorderRadius.circular(MossRadii.md),
                onTap: () => onSelectDate(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day'),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 20,
                      height: 4,
                      child: AnimatedScale(
                        duration: MossMotion.duration(context, MossMotion.fast),
                        curve: MossMotion.stateCurve,
                        scale: count == 0
                            ? 0
                            : (8 + count.clamp(1, 4) * 3) / 20,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius: BorderRadius.circular(MossRadii.full),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AgendaEmptyState extends StatelessWidget {
  const _AgendaEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MossSpacing.x8),
      decoration: BoxDecoration(
        color: theme.surfaceMuted,
        borderRadius: BorderRadius.circular(MossRadii.lg),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, color: theme.primary, size: 40),
          const SizedBox(height: MossSpacing.x3),
          Text('วันนี้ยังว่าง', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: MossSpacing.x1),
          Text(
            'เพิ่มงาน แล้ว Moss จะช่วยหาช่วงเวลาที่เหมาะให้',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Container(
      margin: const EdgeInsets.only(top: MossSpacing.x3),
      padding: const EdgeInsets.all(MossSpacing.x3),
      decoration: BoxDecoration(
        color: context.mossComponents.urgentSurface,
        borderRadius: BorderRadius.circular(MossRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem_rounded, color: theme.error),
          const SizedBox(width: MossSpacing.x2),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
        ],
      ),
    );
  }
}
