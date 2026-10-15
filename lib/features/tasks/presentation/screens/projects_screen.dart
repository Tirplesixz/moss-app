import 'package:flutter/material.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/moss_entrance.dart';
import '../../domain/task.dart';

class ProjectsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final groups = <String, List<Task>>{};
    for (final task in tasks) {
      final name = task.projectName?.trim();
      final key = name == null || name.isEmpty ? 'ยังไม่จัดโปรเจกต์' : name;
      groups.putIfAbsent(key, () => []).add(task);
    }
    final entries = groups.entries.toList()
      ..sort((a, b) {
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
                          IconButton.filledTonal(
                            tooltip: 'เพิ่มงานในโปรเจกต์',
                            onPressed: onAddTask,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: MossSpacing.x5),
                    ],
                  ),
                ),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ProjectsEmptyState(onAddTask: onAddTask),
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
                                  onOpenTask: onOpenTask,
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
                              onOpenTask: onOpenTask,
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
    final components = context.mossComponents;
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
        onTap: preview.isEmpty ? null : () => onOpenTask(preview.first),
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
                      color: components.projectSurface,
                      borderRadius: BorderRadius.circular(MossRadii.md),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: components.projectAccent,
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
                  color: components.projectAccent,
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
  const _ProjectsEmptyState({required this.onAddTask});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
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
