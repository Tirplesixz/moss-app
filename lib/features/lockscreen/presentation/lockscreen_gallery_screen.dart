import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/moss_page_route.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/moss_haptics.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/block.dart';
import '../domain/lockscreen_config.dart';
import 'lockscreen_editor_screen.dart';
import 'widgets/lockscreen_canvas.dart';

class LockScreenTab extends ConsumerStatefulWidget {
  const LockScreenTab({super.key});

  @override
  ConsumerState<LockScreenTab> createState() => _LockScreenTabState();
}

class _LockScreenTabState extends ConsumerState<LockScreenTab> {
  String _category = 'ทั้งหมด';

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(lockScreenViewModelProvider);
    final theme = context.mossTheme;
    final presets = _category == 'ทั้งหมด'
        ? lockScreenPresets
        : lockScreenPresets
              .where((item) => item.category == _category)
              .toList();

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: viewModel.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: viewModel.load,
                child: CustomScrollView(
                  key: const PageStorageKey('lockscreen-gallery'),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ล็อกสกรีน',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ให้งานสำคัญอยู่ในสายตา แม้ยังไม่เปิดแอป',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: theme.textSecondary),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final category in const [
                                  'ทั้งหมด',
                                  'งาน',
                                  'ปฏิทิน',
                                  'ธรรมชาติ',
                                  'มินิมอล',
                                ])
                                  ChoiceChip(
                                    label: Text(category),
                                    selected: _category == category,
                                    onSelected: (_) {
                                      MossHaptics.selection();
                                      setState(() => _category = category);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: viewModel.config.autoUpdate
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFE5A93B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      viewModel.config.autoUpdate
                                          ? 'อัปเดตอัตโนมัติเปิดอยู่ (อัปเดตเมื่อมีงานใหม่/เสร็จ)'
                                          : 'อัปเดตอัตโนมัติปิดอยู่',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: theme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: viewModel.config.autoUpdate,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF4CAF50),
                                    onChanged: (val) async {
                                      MossHaptics.selection();
                                      viewModel.setAutoUpdate(val);
                                      await viewModel.save();
                                      if (val) {
                                        ref
                                            .read(lockScreenSyncServiceProvider)
                                            .syncIfEnabled(force: true)
                                            .then<void>((_) {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.58,
                            ),
                        itemCount: presets.length,
                        itemBuilder: (context, index) {
                          final preset = presets[index];
                          final selected =
                              viewModel.config.templateId == preset.id;
                          return _PresetCard(
                            preset: preset,
                            selected: selected,
                            tasks: viewModel.tasks,
                            blocks: viewModel.blocks,
                            onTap: () => _openEditor(preset),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      sliver: SliverToBoxAdapter(
                        child: OutlinedButton.icon(
                          onPressed: () => _openEditor(null),
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(
                            viewModel.hasChanges
                                ? 'ปรับแต่งฉบับร่างต่อ'
                                : 'ปรับแต่งเทมเพลตปัจจุบัน',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _openEditor(LockScreenPreset? preset) async {
    final viewModel = ref.read(lockScreenViewModelProvider);
    if (preset != null) viewModel.selectPreset(preset);
    await Navigator.of(
      context,
    ).push(mossPageRoute<void>(context, const LockScreenEditorScreen()));
    if (mounted) setState(() {});
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.tasks,
    required this.blocks,
    required this.onTap,
  });
  final LockScreenPreset preset;
  final bool selected;
  final List<Task> tasks;
  final List<Block> blocks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = preset.toConfig();
    return Semantics(
      button: true,
      selected: selected,
      label: 'เทมเพลต ${preset.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LockScreenCanvas(
                      config: config,
                      tasks: tasks,
                      blocks: blocks,
                      compact: true,
                    ),
                    if (selected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
