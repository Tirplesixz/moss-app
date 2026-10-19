import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/moss_motion.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../../core/utils/thai_date_formatter.dart';
import '../../../stats/presentation/stats_screen.dart';
import '../../../tasks/domain/matrix_board.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/matrix_boards_controller.dart';
import '../../../tasks/presentation/screens/add_task_screen.dart';
import '../today_controller.dart';

part 'matrix_tasks_screen_widgets.dart';

/// The primary Eisenhower Matrix workspace.
class MatrixTasksScreen extends ConsumerStatefulWidget {
  const MatrixTasksScreen({
    super.key,
    required this.onOpenTask,
    required this.onAddTask,
    this.onAddTaskQuadrant,
  });

  final ValueChanged<Task> onOpenTask;
  final VoidCallback onAddTask;
  final void Function(int quadrant)? onAddTaskQuadrant;

  @override
  ConsumerState<MatrixTasksScreen> createState() => _MatrixTasksScreenState();
}

class _MatrixTasksScreenState extends ConsumerState<MatrixTasksScreen> {
  bool _isGridView = true;
  int? _justDroppedQuadrant;
  String? _justMovedTaskId;

  int _calculateStreak(List<Task> allTasks) {
    final doneTasks = allTasks
        .where((t) => t.status == TaskStatus.done)
        .toList();
    if (doneTasks.isEmpty) return 0;

    final datesWithCompletedTasks =
        doneTasks
            .map((t) {
              final d = t.updatedAt.toLocal();
              return DateTime(d.year, d.month, d.day);
            })
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(Duration(days: 1));

    if (!datesWithCompletedTasks.contains(todayDate) &&
        !datesWithCompletedTasks.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = datesWithCompletedTasks.contains(todayDate)
        ? todayDate
        : yesterdayDate;

    while (datesWithCompletedTasks.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(Duration(days: 1));
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final boardsState = ref.watch(matrixBoardsControllerProvider);
    final activeBoard = boardsState.activeBoard;
    final allTasks = state.allTasks;

    final filteredTasks = allTasks.where((t) {
      if (t.status != TaskStatus.todo) return false;
      if (activeBoard.isDefault) return true;
      final boardKeyword = activeBoard.name.toLowerCase();
      final match =
          (t.projectName?.toLowerCase().contains(boardKeyword) ?? false) ||
          t.title.toLowerCase().contains(boardKeyword) ||
          (t.note?.toLowerCase().contains(boardKeyword) ?? false);
      if (activeBoard.name == 'งานและออฟฟิศ') {
        return match ||
            (t.projectName?.contains('งาน') ?? false) ||
            (t.projectName?.contains('ออฟฟิศ') ?? false) ||
            t.title.contains('งาน') ||
            (t.note?.contains('งาน') ?? false);
      } else if (activeBoard.name == 'ชีวิตส่วนตัว') {
        return match ||
            (t.projectName?.contains('ส่วนตัว') ?? false) ||
            t.title.contains('ส่วนตัว') ||
            t.title.contains('บ้าน') ||
            (t.note?.contains('ส่วนตัว') ?? false);
      } else if (activeBoard.name == 'การเรียนรู้ & โปรเจกต์') {
        return match ||
            (t.projectName?.contains('เรียน') ?? false) ||
            (t.projectName?.contains('โปรเจกต์') ?? false) ||
            t.title.contains('เรียน') ||
            t.title.contains('โปรเจกต์');
      }
      return match;
    }).toList();

    final q1Tasks = filteredTasks.where((t) => t.quadrant == 1).toList();
    final q2Tasks = filteredTasks.where((t) => t.quadrant == 2).toList();
    final q3Tasks = filteredTasks.where((t) => t.quadrant == 3).toList();
    final q4Tasks = filteredTasks.where((t) => t.quadrant == 4).toList();

    final doneTasks = allTasks
        .where((t) => t.status == TaskStatus.done)
        .toList();
    final doneCount = doneTasks.length;
    final streakCount = _calculateStreak(allTasks);

    final theme = context.mossTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Short, glanceable greeting keeps the matrix above the fold.
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สวัสดี!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'วันนี้มีอะไรบ้าง?',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.72),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Streak Pill
                  Semantics(
                    button: true,
                    label: 'ดูสถิติและสรุปสัปดาห์ ทำต่อเนื่อง $streakCount วัน',
                    child: Tooltip(
                      message: 'แตะเพื่อดูสถิติและสรุปสัปดาห์',
                      child: InkWell(
                        onTap: () {
                          MossHaptics.light();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const StatsScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: context.mossTheme.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.mossTheme.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 16,
                                color: Color(0xFFF5A623),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$streakCount',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Bar matching reference design:
            // [เมทริกซ์ 4 ช่อง ▾]   [✓ ทำแล้ว N]   [ ⊞ | ☰ ]   [ ? ]
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Matrix selector
                    Semantics(
                      button: true,
                      label: 'เลือกมุมมองเมทริกซ์ ปัจจุบัน ${activeBoard.name}',
                      child: InkWell(
                        onTap: () => _openMatrixSelector(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                activeBoard.icon,
                                size: 14,
                                color: activeBoard.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activeBoard.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: context.mossTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Completed tasks
                  Semantics(
                    button: true,
                    label: 'ดูงานที่ทำแล้ว $doneCount รายการ',
                    child: InkWell(
                      onTap: () => _openCompletedTasksSheet(context, doneTasks),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: context.mossTheme.success,
                            ),
                            const SizedBox(width: 5),
                            AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : MossMotion.fast,
                              child: Text(
                                'ทำแล้ว $doneCount',
                                key: ValueKey<int>(doneCount),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Grid / List View Toggle Pill
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ViewSwitchButton(
                          icon: Icons.grid_view_rounded,
                          label: 'มุมมองตาราง',
                          isSelected: _isGridView,
                          onTap: () {
                            MossHaptics.selection();
                            setState(() => _isGridView = true);
                          },
                        ),
                        _ViewSwitchButton(
                          icon: Icons.view_list_rounded,
                          label: 'มุมมองรายการ',
                          isSelected: !_isGridView,
                          onTap: () {
                            MossHaptics.selection();
                            setState(() => _isGridView = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'คู่มือเมทริกซ์ 4 ช่อง',
                    icon: Icon(
                      Icons.help_outline_rounded,
                      size: 20,
                      color: context.mossTheme.textSecondary,
                    ),
                    onPressed: () => _openMatrixGuideSheet(context),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Main Content Area: 4 Quadrants or List View with AnimatedSwitcher
          Expanded(
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : MossMotion.fast,
              switchInCurve: MossMotion.enterCurve,
              switchOutCurve: MossMotion.enterCurve,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.97,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _isGridView
                  ? KeyedSubtree(
                      key: ValueKey('grid_view_${activeBoard.id}'),
                      child: _buildMatrixGrid(
                        context,
                        q1Tasks,
                        q2Tasks,
                        q3Tasks,
                        q4Tasks,
                        activeBoard,
                      ),
                    )
                  : KeyedSubtree(
                      key: ValueKey('list_view_${activeBoard.id}'),
                      child: _buildListView(context, allTasks),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMatrixGrid(
    BuildContext context,
    List<Task> q1,
    List<Task> q2,
    List<Task> q3,
    List<Task> q4,
    MatrixBoard board,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final needsScrollableGrid =
            constraints.maxWidth >= MossBreakpoints.expanded ||
            constraints.maxHeight < 560;
        if (!needsScrollableGrid) {
          return _buildPortraitMatrixGrid(context, q1, q2, q3, q4, board);
        }

        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final height = constraints.maxHeight < 560 ? 300.0 : 420.0;
        final entries = <(int, List<Task>)>[(1, q1), (2, q2), (3, q3), (4, q4)];
        return GridView(
          key: PageStorageKey<String>('matrix-adaptive-grid-${board.id}'),
          cacheExtent: 800,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: height,
          ),
          children: [
            for (final entry in entries)
              _buildQuadrantCard(entry.$1, entry.$2, board),
          ],
        );
      },
    );
  }

  Widget _buildQuadrantCard(int quadrant, List<Task> tasks, MatrixBoard board) {
    final titles = <int, String>{
      1: board.q1Name,
      2: board.q2Name,
      3: board.q3Name,
      4: board.q4Name,
    };
    final icons = <int, IconData>{
      1: Icons.local_fire_department_rounded,
      2: Icons.calendar_today_rounded,
      3: Icons.bolt_rounded,
      4: Icons.menu_rounded,
    };
    final accent = AppColors.quadrantFor(quadrant);
    return _QuadrantCard(
      quadrantId: quadrant,
      title: titles[quadrant] ?? 'ช่อง $quadrant',
      headerIcon: icons[quadrant]!,
      headerIconColor: accent,
      headerBgColor: accent.withValues(alpha: 0.12),
      accentColor: accent,
      taskCount: tasks.length,
      tasks: tasks,
      isTargetOfDrop: _justDroppedQuadrant == quadrant,
      recentlyMovedTaskId: _justMovedTaskId,
      onAdd: () => _openAddTaskForQuadrant(quadrant, board),
      onComplete: _toggleTaskComplete,
      onTapTask: widget.onOpenTask,
      onTaskDropped: (task) => _moveTaskToQuadrant(task, quadrant),
    );
  }

  Widget _buildPortraitMatrixGrid(
    BuildContext context,
    List<Task> q1,
    List<Task> q2,
    List<Task> q3,
    List<Task> q4,
    MatrixBoard board,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildQuadrantCard(1, q1, board)),
                SizedBox(width: 12),
                Expanded(child: _buildQuadrantCard(2, q2, board)),
              ],
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildQuadrantCard(3, q3, board)),
                SizedBox(width: 12),
                Expanded(child: _buildQuadrantCard(4, q4, board)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'ไม่มีรายการงาน',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      );
    }

    final activeTasks = tasks
        .where((t) => t.status == TaskStatus.todo)
        .toList();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: activeTasks.length,
      itemBuilder: (context, index) {
        final task = activeTasks[index];
        final quadrant = MatrixQuadrant.fromId(task.quadrant);
        return Hero(
          tag: 'task_${task.id}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                leading: GestureDetector(
                  onTap: () => _toggleTaskComplete(task),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                    child: Container(
                      key: ValueKey<bool>(task.isCompleted),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? AppColors.success
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: task.isCompleted
                            ? null
                            : Border.all(
                                color: AppColors.quadrantFor(quadrant.id),
                                width: 2,
                              ),
                      ),
                      child: task.isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.black,
                            )
                          : null,
                    ),
                  ),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.64)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  quadrant.label,
                  style: TextStyle(
                    color: AppColors.quadrantFor(quadrant.id),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.64),
                ),
                onTap: () => widget.onOpenTask(task),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddTaskForQuadrant(int quadrant, MatrixBoard board) async {
    MossHaptics.light();
    if (widget.onAddTaskQuadrant != null) {
      widget.onAddTaskQuadrant!(quadrant);
      return;
    }
    final result = await AddTaskScreen.show(
      context,
      initialQuadrant: quadrant,
      initialProject: board.isDefault ? null : board.name,
    );
    if (result != null && result is Task) {
      await ref.read(todayControllerProvider.notifier).addManualTask(result);
    }
  }

  Future<void> _toggleTaskComplete(Task task) async {
    MossHaptics.success();
    await ref.read(todayControllerProvider.notifier).completeTask(task);
  }

  Future<void> _moveTaskToQuadrant(Task task, int newQuadrant) async {
    if (task.quadrant == newQuadrant) return;
    MossHaptics.success();
    setState(() {
      _justDroppedQuadrant = newQuadrant;
      _justMovedTaskId = task.id;
    });
    final updated = task.copyWith(
      quadrant: newQuadrant,
      priority: MatrixQuadrant.fromId(newQuadrant).priority,
    );
    await ref.read(todayControllerProvider.notifier).updateTask(updated);

    Future.delayed(Duration(milliseconds: 700), () {
      if (mounted && _justMovedTaskId == task.id) {
        setState(() {
          _justDroppedQuadrant = null;
          _justMovedTaskId = null;
        });
      }
    });
  }

  void _openMatrixSelector(BuildContext context) {
    MossHaptics.selection();
    final boardsController = ref.read(matrixBoardsControllerProvider.notifier);
    final boardsState = ref.read(matrixBoardsControllerProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MatrixSelectorSheet(
        boards: boardsState.boards,
        activeBoard: boardsState.activeBoard,
        onSelect: (board) {
          boardsController.selectBoard(board);
        },
        onCreate: () => _openCreateBoardDialog(context),
        onEdit: (board) => _openEditBoardDialog(context, board),
        onDelete: (board) async {
          await boardsController.deleteBoard(board.id);
        },
      ),
    );
  }

  Future<void> _openCreateBoardDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BoardFormSheet(
        title: 'สร้างเมทริกซ์ใหม่',
        onSave: (name, iconCode, colorValue, q1, q2, q3, q4) async {
          await ref.read(matrixBoardsControllerProvider.notifier).createBoard(
                name: name,
                iconCode: iconCode,
                colorValue: colorValue,
                q1Name: q1,
                q2Name: q2,
                q3Name: q3,
                q4Name: q4,
              );
        },
      ),
    );
  }

  Future<void> _openEditBoardDialog(BuildContext context, MatrixBoard board) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BoardFormSheet(
        title: 'แก้ไขเมทริกซ์และชื่อช่อง',
        initialBoard: board,
        onSave: (name, iconCode, colorValue, q1, q2, q3, q4) async {
          final updated = board.copyWith(
            name: name,
            iconCode: iconCode,
            colorValue: colorValue,
            q1Name: q1,
            q2Name: q2,
            q3Name: q3,
            q4Name: q4,
          );
          await ref.read(matrixBoardsControllerProvider.notifier).updateBoard(updated);
        },
      ),
    );
  }

  void _openCompletedTasksSheet(BuildContext context, List<Task> doneTasks) {
    MossHaptics.selection();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompletedTasksSheet(
        tasks: doneTasks,
        onRestore: (task) async {
          MossHaptics.success();
          await ref.read(todayControllerProvider.notifier).uncompleteTask(task);
        },
        onOpenTask: widget.onOpenTask,
      ),
    );
  }

  void _openMatrixGuideSheet(BuildContext context) {
    MossHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _EisenhowerGuideSheet(),
    );
  }
}
