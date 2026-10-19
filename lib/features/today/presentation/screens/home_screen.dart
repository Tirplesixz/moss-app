import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/moss_page_route.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/moss_motion.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../../notes/presentation/note_editor_screen.dart';
import '../../../notes/presentation/notes_screen.dart';
import '../../../tasks/domain/block.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/screens/add_task_screen.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../today_controller.dart';
import '../widgets/add_action_sheet.dart';
import 'calendar_timeline_screen.dart';
import 'lockscreen_tab.dart';
import 'matrix_tasks_screen.dart';

enum _MossDestination {
  today('งาน', Icons.grid_view_outlined, Icons.grid_view_rounded),
  calendar(
    'ปฏิทิน',
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
  ),
  lockScreen(
    'ล็อกสกรีน',
    Icons.screen_lock_portrait_outlined,
    Icons.screen_lock_portrait_rounded,
  ),
  notes('โน้ต', Icons.note_alt_outlined, Icons.note_alt_rounded),
  settings('ตั้งค่า', Icons.settings_outlined, Icons.settings_rounded);

  const _MossDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// State-preserving application shell.
///
/// Keeps each primary workspace alive so filters, scroll positions, and form
/// state survive destination changes.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  DateTime _calendarSelectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref
            .read(lockScreenSyncServiceProvider)
            .syncIfEnabled()
            .then<void>((_) {}),
      );
      unawaited(ref.read(todayControllerProvider.notifier).load());
      unawaited(
        ref
            .read(deviceCalendarViewModelProvider)
            .checkAndLoadSilently(
              DateTime.now(),
              onGranted: () async {
                final settings =
                    await ref.read(settingsRepositoryProvider).getSettings();
                if (settings.saveCompletedToCalendar) {
                  await ref
                      .read(calendarTaskSyncServiceProvider)
                      .syncAllTodoTasks();
                }
              },
            ),
      );
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(
        ref
            .read(lockScreenSyncServiceProvider)
            .syncIfEnabled()
            .then<void>((_) {}),
      );
    }
  }

  Future<void> _openAddTaskAction([DateTime? initialDate]) async {
    MossHaptics.light();
    final action = await AddActionSheet.show(context);
    if (action == null || !mounted) return;

    if (action == AddActionType.note) {
      await Navigator.of(
        context,
      ).push(mossPageRoute<void>(context, const NoteEditorScreen()));
      return;
    }

    final result = await AddTaskScreen.show(
      context,
      initialDate: initialDate,
      initialQuadrant: switch (action) {
        AddActionType.event => 2,
        AddActionType.note => 4,
        AddActionType.task => 1,
      },
    );
    if (result == null || !mounted) return;
    await _saveCreatedItem(result);
  }

  Future<void> _openAddTaskDirect([String? title, int? quadrant]) async {
    final result = await AddTaskScreen.show(
      context,
      initialTitle: title,
      initialQuadrant: quadrant,
    );
    if (result == null || !mounted) return;
    await _saveCreatedItem(result);
  }

  Future<void> _saveCreatedItem(Object result) async {
    final controller = ref.read(todayControllerProvider.notifier);
    if (result is Block) {
      await controller.addFixedBlock(result);
    } else if (result is Task) {
      await controller.addManualTask(result);
    }
  }

  Future<void> _openTask(Task task) => Navigator.of(context).push(
    mossPageRoute<void>(
      context,
      TaskDetailScreen(taskId: task.id, initialTask: task),
    ),
  );

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    MossHaptics.selection();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final mossTheme = context.mossTheme;
    final showAddTask = _selectedIndex == 0 || _selectedIndex == 1;
    final pages = <Widget>[
      MatrixTasksScreen(
        onOpenTask: _openTask,
        onAddTask: () => _openAddTaskAction(),
        onAddTaskQuadrant: (quadrant) => _openAddTaskDirect(null, quadrant),
      ),
      CalendarTimelineScreen(
        onOpenTask: _openTask,
        onAddTask: _openAddTaskAction,
        onSelectedDayChanged: (day) => _calendarSelectedDay = day,
      ),
      const LockScreenTab(),
      const NotesScreen(),
      const SettingsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth >= MossBreakpoints.expanded;
        final content = IndexedStack(
          index: _selectedIndex,
          sizing: StackFit.expand,
          children: pages,
        );

        if (expanded) {
          return Scaffold(
            backgroundColor: mossTheme.background,
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: _selectDestination,
                    destinations: [
                      for (final item in _MossDestination.values)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                  VerticalDivider(width: 1, color: mossTheme.divider),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: MossBreakpoints.maxContentWidth,
                        ),
                        child: content,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: showAddTask
                ? FloatingActionButton(
                    tooltip: 'เพิ่มงาน เหตุการณ์ หรือโน้ต',
                    onPressed: () => _openAddTaskAction(
                      _selectedIndex == 1 ? _calendarSelectedDay : null,
                    ),
                    child: const Icon(Icons.add_rounded),
                  )
                : null,
          );
        }

        return Scaffold(
          backgroundColor: mossTheme.background,
          body: content,
          floatingActionButton: AnimatedSwitcher(
            duration: MossMotion.duration(
              context,
              const Duration(milliseconds: 180),
            ),
            child: showAddTask
                ? FloatingActionButton(
                    key: const ValueKey('add-fab'),
                    tooltip: 'เพิ่มงาน เหตุการณ์ หรือโน้ต',
                    onPressed: () => _openAddTaskAction(
                      _selectedIndex == 1 ? _calendarSelectedDay : null,
                    ),
                    child: const Icon(Icons.add_rounded),
                  )
                : const SizedBox.shrink(key: ValueKey('no-fab')),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: mossTheme.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.28
                          : 0.08,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: NavigationBar(
                  height: 68,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: [
                    for (final item in _MossDestination.values)
                      NavigationDestination(
                        key: ValueKey('nav-${item.name}'),
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                        tooltip: item.label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
