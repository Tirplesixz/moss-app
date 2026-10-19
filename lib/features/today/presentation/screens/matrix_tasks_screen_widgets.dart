part of 'matrix_tasks_screen.dart';

class _ViewSwitchButton extends StatelessWidget {
  const _ViewSwitchButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        excludeFromSemantics: true,
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.black
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the 4 Eisenhower quadrant cards matching reference screenshots.
class _QuadrantCard extends StatelessWidget {
  const _QuadrantCard({
    required this.quadrantId,
    required this.title,
    required this.headerIcon,
    required this.headerIconColor,
    required this.headerBgColor,
    required this.accentColor,
    required this.taskCount,
    required this.tasks,
    required this.onAdd,
    required this.onComplete,
    required this.onTapTask,
    required this.onTaskDropped,
    this.isTargetOfDrop = false,
    this.recentlyMovedTaskId,
  });

  final int quadrantId;
  final String title;
  final IconData headerIcon;
  final Color headerIconColor;
  final Color headerBgColor;
  final Color accentColor;
  final int taskCount;
  final List<Task> tasks;
  final VoidCallback onAdd;
  final ValueChanged<Task> onComplete;
  final ValueChanged<Task> onTapTask;
  final ValueChanged<Task> onTaskDropped;
  final bool isTargetOfDrop;
  final String? recentlyMovedTaskId;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.quadrant != quadrantId,
      onAcceptWithDetails: (details) {
        onTaskDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return TweenAnimationBuilder<double>(
          key: ValueKey('quadrant_${quadrantId}_$isTargetOfDrop'),
          tween: Tween<double>(begin: isTargetOfDrop ? 0.0 : 1.0, end: 1.0),
          duration: Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, bounceValue, child) {
            final scale = isTargetOfDrop ? (0.98 + 0.02 * bounceValue) : 1.0;

            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isHovered
                      ? accentColor.withValues(alpha: 0.08)
                      : (isTargetOfDrop
                            ? accentColor.withValues(alpha: 0.05)
                            : Theme.of(context).colorScheme.surface),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isHovered || isTargetOfDrop)
                        ? accentColor.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: (isHovered || isTargetOfDrop) ? 1.5 : 1.0,
                  ),
                  boxShadow: isHovered
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                padding: EdgeInsets.all(14),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: headerBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(headerIcon, size: 16, color: headerIconColor),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (taskCount > 0) ...[
                    Text(
                      '$taskCount',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                  ],
                  IconButton.filledTonal(
                    tooltip: 'เพิ่มงานใน$title',
                    onPressed: onAdd,
                    icon: Icon(Icons.add_rounded, size: 20),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Items or Empty Placeholder
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              headerIcon,
                              size: 28,
                              color: accentColor.withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: InkWell(
                                onTap: onAdd,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isHovered
                                          ? accentColor.withValues(alpha: 0.5)
                                          : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant
                                                .withValues(alpha: 0.35),
                                      width: 1.0,
                                    ),
                                    color: isHovered
                                        ? accentColor.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_rounded,
                                        size: 15,
                                        color: isHovered
                                            ? accentColor
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.64),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isHovered
                                            ? 'วางที่นี่'
                                            : 'แตะเพื่อเพิ่ม',
                                        style: TextStyle(
                                          color: isHovered
                                              ? accentColor
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.64),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final isJustMoved = task.id == recentlyMovedTaskId;

                          Widget taskWidget = Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(
                                alpha: isJustMoved ? 0.18 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isJustMoved
                                    ? accentColor.withValues(alpha: 0.8)
                                    : Colors.transparent,
                                width: isJustMoved ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => onComplete(task),
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                    child: Container(
                                      key: ValueKey<bool>(task.isCompleted),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: task.isCompleted
                                            ? AppColors.success
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: task.isCompleted
                                            ? null
                                            : Border.all(
                                                color: accentColor.withValues(
                                                  alpha: 0.6,
                                                ),
                                                width: 1.5,
                                              ),
                                      ),
                                      child: task.isCompleted
                                          ? Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Colors.black,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: task.isCompleted
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.64)
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                          decoration: task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      if (task.deadlineAt
                                          case final deadline?) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          '${ThaiDateFormatter.formatDate(deadline.toLocal())} · ${ThaiDateFormatter.formatTime(deadline.toLocal())}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );

                          // Refined native drop-in animation for recently moved task card
                          Widget animatedTaskItem = isJustMoved
                              ? TweenAnimationBuilder<double>(
                                  key: ValueKey('moved_task_${task.id}'),
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animVal, child) {
                                    return Transform.scale(
                                      scale: 0.96 + (0.04 * animVal),
                                      child: Opacity(
                                        opacity: 0.5 + (0.5 * animVal),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: taskWidget,
                                )
                              : taskWidget;

                          return Hero(
                            tag: 'task_${task.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: LongPressDraggable<Task>(
                                data: task,
                                delay: Duration(milliseconds: 180),
                                onDragStarted: () => MossHaptics.heavy(),
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Transform.rotate(
                                    angle: -0.02,
                                    child: Transform.scale(
                                      scale: 1.03,
                                      child: Container(
                                        width: 175,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: accentColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 16,
                                              offset: Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: accentColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: accentColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.25,
                                  child: taskWidget,
                                ),
                                child: GestureDetector(
                                  onTap: () => onTapTask(task),
                                  child: animatedTaskItem,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom Sheet showing completed tasks with ability to restore (Undo)
class _CompletedTasksSheet extends StatelessWidget {
  const _CompletedTasksSheet({
    required this.tasks,
    required this.onRestore,
    required this.onOpenTask,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onRestore;
  final ValueChanged<Task> onOpenTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ทำเสร็จแล้ว (${tasks.length})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'ยังไม่มีงานที่ทำเสร็จในรายการ',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.64),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final quadrant = MatrixQuadrant.fromId(task.quadrant);
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.64),
                              decoration: TextDecoration.lineThrough,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            quadrant.label,
                            style: TextStyle(
                              color: AppColors.quadrantFor(quadrant.id),
                              fontSize: 12,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              onRestore(task);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'กู้คืน',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            onOpenTask(task);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet for switching active matrix
/// Bottom Sheet for switching active matrix with full customization
class _MatrixSelectorSheet extends StatelessWidget {
  const _MatrixSelectorSheet({
    required this.boards,
    required this.activeBoard,
    required this.onSelect,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<MatrixBoard> boards;
  final MatrixBoard activeBoard;
  final ValueChanged<MatrixBoard> onSelect;
  final VoidCallback onCreate;
  final ValueChanged<MatrixBoard> onEdit;
  final ValueChanged<MatrixBoard> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เลือกเมทริกซ์',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onCreate();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('สร้างใหม่'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: boards.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final board = boards[index];
                final isSelected = board.id == activeBoard.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: board.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(board.icon, color: board.color, size: 20),
                  ),
                  title: Text(
                    board.name,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Q1: ${board.q1Name} • Q2: ${board.q2Name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontSize: 11.5,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'แก้ไขชื่อช่องและเมทริกซ์',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit(board);
                        },
                      ),
                      if (!board.isDefault && boards.length > 1)
                        IconButton(
                          tooltip: 'ลบเมทริกซ์นี้',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete(board);
                          },
                        ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.check_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    MossHaptics.selection();
                    onSelect(board);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Form sheet to create or edit a Matrix Board and customize its 4 quadrant names
class _BoardFormSheet extends StatefulWidget {
  const _BoardFormSheet({
    required this.title,
    this.initialBoard,
    required this.onSave,
  });

  final String title;
  final MatrixBoard? initialBoard;
  final void Function(
    String name,
    int iconCode,
    int colorValue,
    String q1,
    String q2,
    String q3,
    String q4,
  ) onSave;

  @override
  State<_BoardFormSheet> createState() => _BoardFormSheetState();
}

class _BoardFormSheetState extends State<_BoardFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _q1Ctrl;
  late final TextEditingController _q2Ctrl;
  late final TextEditingController _q3Ctrl;
  late final TextEditingController _q4Ctrl;
  late int _selectedColor;
  late int _selectedIcon;

  static const _colors = [
    0xFFF5A623,
    0xFF0A84FF,
    0xFFFF453A,
    0xFF34D399,
    0xFFAF52DE,
    0xFFFF9F0A,
    0xFF64D2FF,
    0xFFFF375F,
  ];

  static const _icons = [
    Icons.grid_view_rounded,
    Icons.work_outline_rounded,
    Icons.favorite_outline_rounded,
    Icons.school_outlined,
    Icons.star_outline_rounded,
    Icons.flag_outlined,
    Icons.rocket_launch_outlined,
    Icons.bookmark_outline_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.fitness_center_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.initialBoard;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _q1Ctrl = TextEditingController(text: b?.q1Name ?? 'สำคัญและเร่งด่วน');
    _q2Ctrl = TextEditingController(text: b?.q2Name ?? 'สำคัญ');
    _q3Ctrl = TextEditingController(text: b?.q3Name ?? 'เร่งด่วน');
    _q4Ctrl = TextEditingController(text: b?.q4Name ?? 'สักวันหนึ่ง');
    _selectedColor = b?.colorValue ?? _colors.first;
    _selectedIcon = b?.iconCode ?? _icons.first.codePoint;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _q1Ctrl.dispose();
    _q2Ctrl.dispose();
    _q3Ctrl.dispose();
    _q4Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อเมทริกซ์',
                hintText: 'เช่น งานส่วนตัว, โปรเจกต์ลูกค้า',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'เลือกสีและไอคอน',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in _colors)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedColor = c),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == c
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: _selectedColor == c
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final icon in _icons)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedIcon = icon.codePoint),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _selectedIcon == icon.codePoint
                                ? Color(_selectedColor).withValues(alpha: 0.2)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedIcon == icon.codePoint
                                  ? Color(_selectedColor)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: _selectedIcon == icon.codePoint
                                ? Color(_selectedColor)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'กำหนดชื่อ 4 ช่องของเมทริกซ์ (Custom Quadrant Names)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _q1Ctrl,
              decoration: InputDecoration(
                labelText: 'ช่องที่ 1 (สำคัญและเร่งด่วน)',
                prefixIcon: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF453A),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _q2Ctrl,
              decoration: InputDecoration(
                labelText: 'ช่องที่ 2 (สำคัญ ไม่เร่งด่วน)',
                prefixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF0A84FF),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _q3Ctrl,
              decoration: InputDecoration(
                labelText: 'ช่องที่ 3 (ไม่สำคัญ เร่งด่วน)',
                prefixIcon: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFF5A623),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _q4Ctrl,
              decoration: InputDecoration(
                labelText: 'ช่องที่ 4 (ไม่สำคัญ ไม่เร่งด่วน)',
                prefixIcon: const Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF34D399),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  MossHaptics.success();
                  widget.onSave(
                    name,
                    _selectedIcon,
                    _selectedColor,
                    _q1Ctrl.text.trim().isEmpty
                        ? 'สำคัญและเร่งด่วน'
                        : _q1Ctrl.text.trim(),
                    _q2Ctrl.text.trim().isEmpty
                        ? 'สำคัญ'
                        : _q2Ctrl.text.trim(),
                    _q3Ctrl.text.trim().isEmpty
                        ? 'เร่งด่วน'
                        : _q3Ctrl.text.trim(),
                    _q4Ctrl.text.trim().isEmpty
                        ? 'สักวันหนึ่ง'
                        : _q4Ctrl.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('บันทึกเมทริกซ์'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Educational bottom sheet explaining the 4 Eisenhower Quadrants
class _EisenhowerGuideSheet extends StatelessWidget {
  const _EisenhowerGuideSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eisenhower Matrix คืออะไร?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'เทคนิคจัดลำดับความสำคัญระดับสากล',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _GuideQuadrantTile(
            color: AppColors.quadrant1,
            quadrantNumber: 'Q1',
            title: 'ด่วน & สำคัญ (Do First)',
            action: 'ต้องทำทันที',
            description: 'วิกฤต ปัญหาเฉพาะหน้า เดดไลน์วันนี้ งานไฟไหม้',
          ),
          const SizedBox(height: 10),
          _GuideQuadrantTile(
            color: AppColors.quadrant2,
            quadrantNumber: 'Q2',
            title: 'ไม่ด่วน แต่สำคัญ (Schedule)',
            action: 'วางแผนเวลาทำ',
            description: 'หัวใจของความก้าวหน้า: พัฒนาตนเอง สุขภาพ วางแผนล่วงหน้า',
            highlighted: true,
          ),
          const SizedBox(height: 10),
          _GuideQuadrantTile(
            color: AppColors.quadrant3,
            quadrantNumber: 'Q3',
            title: 'ด่วน แต่ไม่สำคัญ (Delegate)',
            action: 'จัดการให้เสร็จเร็วหรือมอบหมาย',
            description: 'งานแทรก การแจ้งเตือน ข้อความที่ดูเหมือนด่วนแต่ไม่ก่อผลลัพธ์',
          ),
          const SizedBox(height: 10),
          _GuideQuadrantTile(
            color: AppColors.quadrant4,
            quadrantNumber: 'Q4',
            title: 'ไม่ด่วน ไม่สำคัญ (Eliminate)',
            action: 'ลดละเลิก หรือทำเมื่อว่าง',
            description: 'กิจกรรมเสียเวลา สิ่งฟุ้งซ่าน โซเชียลมีเดียที่เกินจำเป็น',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }
}

class _GuideQuadrantTile extends StatelessWidget {
  const _GuideQuadrantTile({
    required this.color,
    required this.quadrantNumber,
    required this.title,
    required this.action,
    required this.description,
    this.highlighted = false,
  });

  final Color color;
  final String quadrantNumber;
  final String title;
  final String action;
  final String description;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? color.withValues(alpha: 0.4) : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              quadrantNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      action,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
