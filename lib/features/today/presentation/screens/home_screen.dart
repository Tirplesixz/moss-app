import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/moss_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../../tasks/domain/block.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/screens/add_task_screen.dart';
import '../../../tasks/presentation/screens/block_detail_sheet.dart';
import '../../../tasks/presentation/screens/inbox_screen.dart';
import '../../../tasks/presentation/screens/projects_screen.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../domain/today_item.dart';
import '../today_controller.dart';
import 'today_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _openAddTask([String? prefillTitle]) async {
    final result = await AddTaskScreen.show(
      context,
      initialTitle: prefillTitle,
    );
    if (result == null || !mounted) return;
    final controller = ref.read(todayControllerProvider.notifier);
    if (result is Block) {
      await controller.addFixedBlock(result);
    } else if (result is Task) {
      await controller.addManualTask(result);
    }
  }

  Future<void> _openTask(Task task) async {
    await Navigator.of(context).push(
      mossPageRoute<void>(
        context,
        TaskDetailScreen(taskId: task.id, initialTask: task),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(mossPageRoute<void>(context, const SettingsScreen()));
  }

  Future<void> _handleTapBlock(TimelineBlockItem item) async {
    final action = await BlockDetailSheet.show(
      context,
      block: item.block,
      task: item.task,
    );
    if (action == null || !mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);
    final unscheduledIds = state.overflowTasks.map((task) => task.id).toSet();
    final destinations = <Widget>[
      TodayDashboard(
        state: state,
        onAddTask: () => _openAddTask(),
        onOpenSettings: _openSettings,
        onOpenBlock: _handleTapBlock,
        onRetry: controller.load,
      ),
      InboxScreen(
        tasks: state.allTasks,
        unscheduledTaskIds: unscheduledIds,
        isLoading: state.isLoading,
        onQuickAdd: controller.quickAddTask,
        onAddTask: () => _openAddTask(),
        onOpenTask: _openTask,
        onCompleteTask: controller.completeTask,
        onReschedule: controller.reschedule,
      ),
      ProjectsScreen(
        tasks: state.allTasks,
        onAddTask: () => _openAddTask(),
        onOpenTask: _openTask,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 840;
        final content = IndexedStack(
          index: _selectedIndex,
          children: destinations,
        );

        if (useRail) {
          return Scaffold(
            backgroundColor: context.mossTheme.background,
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() => _selectedIndex = value);
                    },
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MossMark(onPressed: _openSettings),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_today_outlined),
                        selectedIcon: Icon(Icons.calendar_today_rounded),
                        label: Text('วันนี้'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.format_list_bulleted_rounded),
                        selectedIcon: Icon(Icons.view_list_rounded),
                        label: Text('งานเข้า'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.folder_outlined),
                        selectedIcon: Icon(Icons.folder_rounded),
                        label: Text('โปรเจกต์'),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: context.mossTheme.background,
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) {
              setState(() => _selectedIndex = value);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today_rounded),
                label: 'วันนี้',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_list_bulleted_rounded),
                selectedIcon: Icon(Icons.view_list_rounded),
                label: 'งานเข้า',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'โปรเจกต์',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MossMark extends StatelessWidget {
  const _MossMark({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return IconButton.filled(
      tooltip: 'การตั้งค่า',
      onPressed: onPressed,
      icon: const Icon(Icons.auto_awesome_rounded),
      style: IconButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: theme.onPrimary,
      ),
    );
  }
}
