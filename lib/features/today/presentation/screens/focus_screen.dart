import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/moss_haptics.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../tasks/domain/task.dart';
import '../today_controller.dart';

/// Distraction-free countdown for the block that is running right now.
///
/// Deliberately has no pause: the schedule keeps moving in real life, so the
/// honest controls are "give me more time" and "I'm done".
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  static const _extendMinutes = 15;

  late final Timer _ticker;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _extend() async {
    MossHaptics.light();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(todayControllerProvider.notifier)
        .extendCurrentBlock(_extendMinutes);
    if (!ok && mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('ขยายเวลาไม่ได้ เพราะชนกับนัดหมายถัดไป'),
          ),
        );
    }
  }

  Future<void> _complete() async {
    MossHaptics.success();
    final controller = ref.read(todayControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await controller.completeCurrentTask();
    final action = controller.lastAction;
    if (action != null) {
      showUndoSnackBar(
        messenger,
        message: action.label,
        onUndo: () => controller.undoLastAction(),
      );
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final state = ref.watch(todayControllerProvider);
    final block = state.nowBlock;
    final task = state.nowTask;

    if (block == null) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(MossSpacing.x8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.spa_rounded, size: 48, color: theme.primary),
                const SizedBox(height: MossSpacing.x3),
                Text(
                  'ช่วงเวลานี้จบแล้ว',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: MossSpacing.x4),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('กลับหน้าหลัก'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = block.endAt.difference(block.startAt).inSeconds;
    final left = block.endAt.difference(_now).inSeconds.clamp(0, total);
    final progress = total <= 0 ? 0.0 : 1 - left / total;
    final minutes = (left ~/ 60).toString().padLeft(2, '0');
    final seconds = (left % 60).toString().padLeft(2, '0');
    final title = block.title ?? task?.title ?? 'งานปัจจุบัน';

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'ออกจากโหมดโฟกัส',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('โหมดโฟกัส'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MossSpacing.x5),
              child: Column(
                children: [
                  const SizedBox(height: MossSpacing.x4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: MossSpacing.x8),
                  Semantics(
                    label: 'เหลืออีก ${left ~/ 60} นาที ${left % 60} วินาที',
                    excludeSemantics: true,
                    child: SizedBox.square(
                      dimension: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: theme.surfaceMuted,
                              color: theme.primary,
                            ),
                          ),
                          Text(
                            '$minutes:$seconds',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontSize: 56,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: MossSpacing.x8),
                  if (task != null && task.checklist.isNotEmpty)
                    _FocusChecklist(task: task),
                  const SizedBox(height: MossSpacing.x6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _extend,
                          icon: const Icon(Icons.more_time_rounded),
                          label: const Text('+$_extendMinutes นาที'),
                        ),
                      ),
                      const SizedBox(width: MossSpacing.x3),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _complete,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('เสร็จแล้ว'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusChecklist extends ConsumerWidget {
  const _FocusChecklist({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.mossTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(MossRadii.lg),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Column(
        children: [
          for (final item in task.checklist)
            CheckboxListTile(
              value: item.done,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                item.title,
                style: TextStyle(
                  decoration: item.done ? TextDecoration.lineThrough : null,
                  color: item.done ? theme.textMuted : theme.onBackground,
                ),
              ),
              onChanged: (value) {
                MossHaptics.selection();
                final updated = [
                  for (final other in task.checklist)
                    other.id == item.id
                        ? other.copyWith(done: value ?? false)
                        : other,
                ];
                ref
                    .read(todayControllerProvider.notifier)
                    .updateChecklist(task, updated);
              },
            ),
        ],
      ),
    );
  }
}
