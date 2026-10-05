import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
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
        toolbarHeight: 68,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.onBackground,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Moss',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.onBackground,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'เพิ่มงาน / นัดหมาย',
            onPressed: () => _openAddTask(context, ref),
            icon: Icon(
              Icons.note_add_outlined,
              color: theme.onBackground,
              size: 21,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              child: Container(
                width: 34,
                height: 34,
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
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
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
                    const SizedBox(height: 18),
                    _WeekStrip(selectedDate: state.currentDate),
                    const SizedBox(height: 18),
                    DoneItemsRow(items: state.doneItems),
                    NowCard(
                      block: state.nowBlock,
                      task: state.nowTask,
                      progress: state.nowProgress,
                      remainingMinutes: state.nowRemainingMinutes,
                      isPaused: state.isPaused,
                      onComplete: () => controller.completeCurrentTask(),
                      onPause: () => controller.togglePause(),
                    ),
                    const SizedBox(height: 28),
                    if (state.overflowTasks.isNotEmpty) ...[
                      _OverflowCard(tasks: state.overflowTasks),
                      const SizedBox(height: 22),
                    ],
                    TimelineSection(
                      items: state.visibleTimelineItems,
                      hasMoreThan4: state.hasMoreThan4Upcoming,
                      isShowingAll: state.showAllUpcoming,
                      totalCount: state.upcomingBlocksCount,
                      onToggleShowAll: () => controller.toggleShowAllUpcoming(),
                      onTapBlock: (item) => _handleTapBlock(context, ref, item),
                    ),
                  ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.urgentAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.urgentAccent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: theme.urgentAccent, size: 19),
              const SizedBox(width: 8),
              Text(
                'ยังต้องหาที่ให้อีก ${tasks.length} งาน',
                style: TextStyle(
                  color: theme.onBackground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tasks.map((task) => task.title).join(' · '),
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            'ลองขยับเดดไลน์หรือลดเวลาของงาน โดยไม่มีงานไหนถูกทิ้งหาย',
            style: TextStyle(color: theme.textMuted, fontSize: 12),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.textSecondary),
          const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? theme.primary : theme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? theme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : theme.onBackground,
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
