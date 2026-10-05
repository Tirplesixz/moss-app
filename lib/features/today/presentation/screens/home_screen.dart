import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/moss_motion.dart';
import '../../../tasks/domain/block.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/screens/add_task_screen.dart';
import '../../../tasks/presentation/screens/block_detail_sheet.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../domain/today_item.dart';
import '../today_controller.dart';
import 'urgent_replan_sheet.dart';
import '../widgets/done_items_row.dart';
import '../widgets/now_card.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/timeline_section.dart';
import '../widgets/today_header.dart';

/// Motion-inspired daily planning screen while retaining Moss task actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openAddTask(
    BuildContext context,
    WidgetRef ref, [
    String? prefillTitle,
  ]) async {
    final result = await AddTaskScreen.show(
      context,
      initialTitle: prefillTitle,
    );
    if (result == null) return;
    final controller = ref.read(todayControllerProvider.notifier);
    if (result is Block) {
      await controller.addFixedBlock(result);
    } else if (result is Task) {
      await controller.addManualTask(result);
    }
  }

  Future<void> _handleTapBlock(
    BuildContext context,
    WidgetRef ref,
    TimelineBlockItem item,
  ) async {
    final action = await BlockDetailSheet.show(
      context,
      block: item.block,
      task: item.task,
    );
    if (action == null) return;

    final controller = ref.read(todayControllerProvider.notifier);
    switch (action) {
      case BlockAction.complete:
        await controller.completeBlock(item.block);
        break;
      case BlockAction.toggleLock:
        await controller.toggleLockBlock(item.block);
        break;
      case BlockAction.delete:
        await controller.deleteBlock(item.block);
        break;
      case BlockAction.edit:
        if (!context.mounted) return;
        final editResult = await AddTaskScreen.show(
          context,
          editBlock: item.block,
          editTask: item.task,
        );
        if (editResult != null) {
          await controller.editBlock(item.block, editResult);
        }
        break;
    }
  }

  Future<void> _handleUrgentAdd(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) async {
    final controller = ref.read(todayControllerProvider.notifier);
    final proposal = await controller.proposeUrgentTask(title);
    if (proposal == null || !context.mounted) return;
    final accepted = await UrgentReplanSheet.show(context, proposal);
    if (accepted != true) {
      controller.cancelUrgentProposal();
      if (accepted == false && context.mounted) {
        await _openAddTask(context, ref, title);
      }
      return;
    }
    await controller.confirmUrgentProposal();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('ใช้ตารางใหม่แล้ว'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'เลิกทำ',
            onPressed: controller.undoLastUrgent,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);
    final theme = context.mossTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: MossSpacing.x8,
              height: MossSpacing.x8,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(MossRadii.md),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: theme.onPrimary,
                size: MossIconSizes.sm,
              ),
            ),
            const SizedBox(width: MossSpacing.x2),
            Text('Moss', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'เพิ่มงาน / นัดหมาย',
            onPressed: () => _openAddTask(context, ref),
            icon: Icon(
              Icons.note_add_outlined,
              color: theme.onBackground,
              size: MossIconSizes.md,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: MossSpacing.x1),
            child: IconButton(
              tooltip: 'การตั้งค่า',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: Container(
                width: MossSpacing.x8,
                height: MossSpacing.x8,
                decoration: BoxDecoration(
                  color: theme.nowFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.borderSubtle),
                ),
                alignment: Alignment.center,
                child: Text(
                  'M',
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.divider),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  MossSpacing.x4,
                  MossSpacing.x5,
                  MossSpacing.x4,
                  MossSpacing.x8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isLoading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: theme.primary,
                              backgroundColor: theme.nowFill,
                            ),
                          ),
                        if (state.errorMessage != null)
                          _StatusCard(
                            icon: Icons.sync_problem_rounded,
                            message: state.errorMessage!,
                            actionLabel: 'ลองอีกครั้ง',
                            onAction: controller.load,
                          ),
                        TodayHeader(date: state.currentDate),
                        const SizedBox(height: MossSpacing.x4),
                        _WeekStrip(selectedDate: state.currentDate),
                        const SizedBox(height: MossSpacing.x4),
                        DoneItemsRow(items: state.doneItems),
                        AnimatedSwitcher(
                          duration: MossMotion.duration(
                            context,
                            MossMotion.standard,
                          ),
                          switchInCurve: MossMotion.enterCurve,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final offset = Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offset,
                                child: child,
                              ),
                            );
                          },
                          child: NowCard(
                            key: ValueKey(
                              '${state.nowBlock?.id ?? 'empty'}-${state.isPaused}',
                            ),
                            block: state.nowBlock,
                            task: state.nowTask,
                            progress: state.nowProgress,
                            remainingMinutes: state.nowRemainingMinutes,
                            isPaused: state.isPaused,
                            onComplete: () => controller.completeCurrentTask(),
                            onPause: () => controller.togglePause(),
                          ),
                        ),
                        const SizedBox(height: MossSpacing.x6),
                        if (state.overflowTasks.isNotEmpty) ...[
                          _OverflowCard(tasks: state.overflowTasks),
                          const SizedBox(height: MossSpacing.x6),
                        ],
                        TimelineSection(
                          items: state.visibleTimelineItems,
                          hasMoreThan4: state.hasMoreThan4Upcoming,
                          isShowingAll: state.showAllUpcoming,
                          totalCount: state.upcomingBlocksCount,
                          onToggleShowAll: () =>
                              controller.toggleShowAllUpcoming(),
                          onTapBlock: (item) =>
                              _handleTapBlock(context, ref, item),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            QuickAddBar(
              onAddTask: (title) => _handleUrgentAdd(context, ref, title),
              onOpenManualForm: (prefill) =>
                  _openAddTask(context, ref, prefill),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowCard extends StatelessWidget {
  final List<Task> tasks;

  const _OverflowCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MossSpacing.x4),
      decoration: BoxDecoration(
        color: components.urgentSurface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(color: components.urgentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: theme.urgentAccent, size: 19),
              const SizedBox(width: MossSpacing.x2),
              Text(
                'ยังต้องหาที่ให้อีก ${tasks.length} งาน',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: MossSpacing.x2),
          Text(
            tasks.map((task) => task.title).join(' · '),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: MossSpacing.x1),
          Text(
            'ลองขยับกำหนดส่งหรือลดเวลาของงาน โดยไม่มีงานไหนถูกทิ้งหาย',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: theme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StatusCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: MossSpacing.x4),
      padding: const EdgeInsets.symmetric(
        horizontal: MossSpacing.x4,
        vertical: MossSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(MossRadii.md),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.textSecondary),
          const SizedBox(width: MossSpacing.x2),
          Expanded(child: Text(message)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;

  const _WeekStrip({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final monday = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    const labels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MossSpacing.x1,
        vertical: MossSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(
          top: BorderSide(color: theme.divider),
          bottom: BorderSide(color: theme.divider),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final day = monday.add(Duration(days: index));
          final selected =
              day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          return Expanded(
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
                  duration: MossMotion.duration(context, MossMotion.standard),
                  curve: MossMotion.stateCurve,
                  width: MossSpacing.x8,
                  height: MossSpacing.x8,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? theme.nowFill : Colors.transparent,
                    borderRadius: BorderRadius.circular(MossRadii.md),
                  ),
                  child: Text(
                    '${day.day}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? theme.primary : theme.onBackground,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
