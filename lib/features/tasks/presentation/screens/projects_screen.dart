import 'package:flutter/material.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/moss_task_style.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../../core/widgets/moss_entrance.dart';
import '../../../../core/validation/input_limits.dart';
import '../../domain/task.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onOpenTask,
  });

  final List<Task> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<Task> onOpenTask;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final groups = <String, List<Task>>{};
    for (final task in widget.tasks) {
      final name = task.projectName?.trim();
      final key = name == null || name.isEmpty ? 'ยังไม่จัดโปรเจกต์' : name;
      groups.putIfAbsent(key, () => []).add(task);
    }

    final q = _query.trim().toLowerCase();
    final entries =
        groups.entries.where((entry) {
          if (q.isEmpty) return true;
          if (entry.key.toLowerCase().contains(q)) return true;
          return entry.value.any((t) => t.title.toLowerCase().contains(q));
        }).toList()..sort((a, b) {
          if (a.key == 'ยังไม่จัดโปรเจกต์') return 1;
          if (b.key == 'ยังไม่จัดโปรเจกต์') return -1;
          return a.key.toLowerCase().compareTo(b.key.toLowerCase());
        });

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MossSpacing.x4,
                    MossSpacing.x6,
                    MossSpacing.x4,
                    MossSpacing.x5,
                  ),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'โปรเจกต์',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                ),
                                const SizedBox(height: MossSpacing.x1),
                                Text(
                                  'เห็นภาพรวมงานที่กำลังเดินอยู่',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: theme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: _searching
                                ? 'ปิดการค้นหา'
                                : 'ค้นหาโปรเจกต์',
                            onPressed: _toggleSearch,
                            icon: Icon(
                              _searching
                                  ? Icons.search_off_rounded
                                  : Icons.search_rounded,
                            ),
                          ),
                          const SizedBox(width: MossSpacing.x1),
                          IconButton.filledTonal(
                            tooltip: 'เพิ่มงานในโปรเจกต์',
                            onPressed: widget.onAddTask,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      if (_searching) ...[
                        const SizedBox(height: MossSpacing.x3),
                        TextField(
                          controller: _searchController,
                          maxLength: InputLimits.projectName,
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
                            hintText: 'ค้นหาโปรเจกต์หรืองานภายใน…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'ล้างคำค้นหา',
                                    icon: const Icon(Icons.cancel_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: MossSpacing.x5),
                    ],
                  ),
                ),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ProjectsEmptyState(
                      onAddTask: widget.onAddTask,
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
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.crossAxisExtent >= 700;
                        if (wide) {
                          return SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 420,
                                  mainAxisExtent: 196,
                                  crossAxisSpacing: MossSpacing.x4,
                                  mainAxisSpacing: MossSpacing.x4,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => MossEntrance(
                                index: index,
                                child: _ProjectCard(
                                  name: entries[index].key,
                                  tasks: entries[index].value,
                                  onOpenTask: widget.onOpenTask,
                                ),
                              ),
                              childCount: entries.length,
                            ),
                          );
                        }
                        return SliverList.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: MossSpacing.x4),
                          itemBuilder: (context, index) => MossEntrance(
                            index: index,
                            child: _ProjectCard(
                              name: entries[index].key,
                              tasks: entries[index].value,
                              onOpenTask: widget.onOpenTask,
                            ),
                          ),
                        );
                      },
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

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.name,
    required this.tasks,
    required this.onOpenTask,
  });

  final String name;
  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final projectColor = MossProjectColors.of(context, name);
    final todo = tasks.where((task) => task.status == TaskStatus.todo).toList();
    final doneCount = tasks.length - todo.length;
    final progress = tasks.isEmpty ? 0.0 : doneCount / tasks.length;
    final preview = todo.take(2).toList();

    return Material(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MossRadii.lg),
        side: BorderSide(color: theme.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: preview.isEmpty
            ? null
            : () {
                MossHaptics.light();
                onOpenTask(preview.first);
              },
        child: Padding(
          padding: const EdgeInsets.all(MossSpacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: projectColor.surface,
                      borderRadius: BorderRadius.circular(MossRadii.md),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: projectColor.accent,
                    ),
                  ),
                  const SizedBox(width: MossSpacing.x3),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${tasks.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: theme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: MossSpacing.x4),
              ClipRRect(
                borderRadius: BorderRadius.circular(MossRadii.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.surfaceMuted,
                  color: projectColor.accent,
                ),
              ),
              const SizedBox(height: MossSpacing.x3),
              if (preview.isEmpty)
                Text(
                  'เสร็จครบแล้ว',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: theme.success),
                )
              else
                ...preview.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: MossSpacing.x1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle_outlined,
                          size: MossIconSizes.sm,
                          color: theme.textMuted,
                        ),
                        const SizedBox(width: MossSpacing.x2),
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}

class _ProjectsEmptyState extends StatelessWidget {
  const _ProjectsEmptyState({required this.onAddTask, this.query = ''});

  final VoidCallback onAddTask;
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
              Icon(Icons.search_off_rounded, size: 48, color: theme.textMuted),
              const SizedBox(height: MossSpacing.x3),
              Text(
                'ไม่พบโปรเจกต์ที่ตรงกับ "$query"',
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
            Icon(Icons.folder_open_outlined, size: 48, color: theme.primary),
            const SizedBox(height: MossSpacing.x3),
            Text(
              'ยังไม่มีโปรเจกต์',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MossSpacing.x2),
            Text(
              'เพิ่มชื่อโปรเจกต์ตอนสร้างงาน แล้วงานจะถูกรวมไว้ที่นี่',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
            const SizedBox(height: MossSpacing.x4),
            ElevatedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('เพิ่มงานแรก'),
            ),
          ],
        ),
      ),
    );
  }
}
