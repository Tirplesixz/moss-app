import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/moss_haptics.dart';
import '../data/lockscreen_platform_service.dart';
import '../data/lockscreen_image_renderer.dart';
import 'lockscreen_view_model.dart';
import 'widgets/lockscreen_canvas.dart';

class LockScreenEditorScreen extends ConsumerStatefulWidget {
  const LockScreenEditorScreen({super.key});

  @override
  ConsumerState<LockScreenEditorScreen> createState() =>
      _LockScreenEditorScreenState();
}

class _LockScreenEditorScreenState
    extends ConsumerState<LockScreenEditorScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(lockScreenViewModelProvider);
    final theme = context.mossTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('ปรับแต่งล็อกสกรีน'),
        actions: [
          TextButton(
            onPressed: viewModel.saving ? null : _saveOnly,
            child: const Text('บันทึก'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final preview = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: wide ? 330 : 270,
                  maxHeight: wide ? 620 : 510,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: LockScreenCanvas(
                    config: viewModel.config,
                    tasks: viewModel.tasks,
                    blocks: viewModel.blocks,
                  ),
                ),
              ),
            );
            final controls = _EditorControls(viewModel: viewModel);

            return Column(
              children: [
                Expanded(
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: preview),
                            VerticalDivider(width: 1, color: theme.divider),
                            SizedBox(width: 380, child: controls),
                          ],
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                18,
                                24,
                                20,
                              ),
                              sliver: SliverToBoxAdapter(child: preview),
                            ),
                            SliverToBoxAdapter(child: controls),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.divider)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _exporting || viewModel.saving
                          ? null
                          : _renderAndApply,
                      icon: _exporting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wallpaper_rounded),
                      label: Text(
                        _exporting
                            ? 'กำลังสร้างภาพ…'
                            : 'สร้างและใช้กับหน้าจอล็อก',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveOnly() async {
    try {
      await ref.read(lockScreenViewModelProvider).save();
      if (!mounted) return;
      MossHaptics.success();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกเทมเพลตแล้ว')));
    } catch (_) {
      _showFailure('บันทึกเทมเพลตไม่สำเร็จ');
    }
  }

  Future<void> _renderAndApply() async {
    setState(() => _exporting = true);
    try {
      final viewModel = ref.read(lockScreenViewModelProvider);
      final bytes = await const LockScreenImageRenderer().render(
        config: viewModel.config,
        tasks: viewModel.tasks,
        blocks: viewModel.blocks,
      );
      final result = await const LockScreenPlatformService().apply(bytes);
      await ref.read(lockScreenViewModelProvider).save(rendered: true);
      if (!mounted) return;
      MossHaptics.success();
      final message = switch (result.action) {
        WallpaperExportAction.applied =>
          'ตั้งภาพหน้าจอล็อกและบันทึกลงเครื่องแล้ว',
        WallpaperExportAction.saved => 'บันทึกภาพลงเครื่องแล้ว',
        WallpaperExportAction.shared =>
          'สร้างภาพแล้ว เลือก “บันทึกรูปภาพ” เพื่อนำไปตั้งเป็นวอลเปเปอร์',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on MissingPluginException {
      _showFailure('การตั้งวอลเปเปอร์รองรับบน Android และ iOS เท่านั้น');
    } catch (_) {
      _showFailure('สร้างภาพไม่สำเร็จ กรุณาลองอีกครั้ง');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _EditorControls extends StatefulWidget {
  const _EditorControls({required this.viewModel});
  final LockScreenViewModel viewModel;

  @override
  State<_EditorControls> createState() => _EditorControlsState();
}

class _EditorControlsState extends State<_EditorControls> {
  late final TextEditingController _countdownTitleController;
  late final TextEditingController _noteTextController;

  @override
  void initState() {
    super.initState();
    _countdownTitleController = TextEditingController(
      text: widget.viewModel.config.countdownTitle,
    );
    _noteTextController = TextEditingController(
      text: widget.viewModel.config.pinnedNoteText,
    );
  }

  @override
  void didUpdateWidget(covariant _EditorControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel.config.countdownTitle != _countdownTitleController.text) {
      _countdownTitleController.text = widget.viewModel.config.countdownTitle;
    }
    if (widget.viewModel.config.pinnedNoteText != _noteTextController.text) {
      _noteTextController.text = widget.viewModel.config.pinnedNoteText;
    }
  }

  @override
  void dispose() {
    _countdownTitleController.dispose();
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final theme = context.mossTheme;
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text('สีพื้นหลัง', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final colors in const [
              (0xFF203B5E, 0xFF0B1524),
              (0xFF315B50, 0xFF0E211D),
              (0xFF67557C, 0xFF211A2A),
              (0xFF8A5E3C, 0xFF2D1D12),
              (0xFF36415F, 0xFF111725),
              (0xFF141416, 0xFF050505),
              (0xFF8B4F58, 0xFF2C161B),
              (0xFF2C4A52, 0xFF101B20),
            ])
              Semantics(
                button: true,
                selected: viewModel.config.gradientStart == colors.$1,
                label: 'เลือกชุดสีพื้นหลัง',
                child: InkWell(
                  onTap: () => viewModel.setColors(colors.$1, colors.$2),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(colors.$1), Color(colors.$2)],
                      ),
                      border: Border.all(
                        color: viewModel.config.gradientStart == colors.$1
                            ? Theme.of(context).colorScheme.primary
                            : theme.borderSubtle,
                        width: viewModel.config.gradientStart == colors.$1
                            ? 3
                            : 1,
                      ),
                    ),
                    child: viewModel.config.gradientStart == colors.$1
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ตำแหน่งเนื้อหา', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '+${viewModel.config.verticalOffset.round()} px',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'เลื่อนลงเพื่อหลบนาฬิการะบบของมือถือ ไม่ให้ทับซ้อน',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: theme.textSecondary),
        ),
        Slider(
          value: viewModel.config.verticalOffset,
          min: 0,
          max: 250,
          divisions: 25,
          label: '+${viewModel.config.verticalOffset.round()} px',
          onChanged: viewModel.setVerticalOffset,
        ),
        const SizedBox(height: 16),
        Text('องค์ประกอบ', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'เลือกและจัดลำดับข้อมูลที่อยากให้ปรากฏบนล็อกสกรีน',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: viewModel.config.moduleOrder.length,
          onReorder: viewModel.moveModule,
          itemBuilder: (context, index) {
            final id = viewModel.config.moduleOrder[index];
            final module = _moduleDefinition(id, viewModel);
            return _ModuleSwitch(
              key: ValueKey(id),
              icon: module.$1,
              label: module.$2,
              value: module.$3,
              onChanged: module.$4,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'เลื่อน ${module.$2} ขึ้น',
                    onPressed: index == 0
                        ? null
                        : () => viewModel.moveModuleBy(id, -1),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                  IconButton(
                    tooltip: 'เลื่อน ${module.$2} ลง',
                    onPressed: index == viewModel.config.moduleOrder.length - 1
                        ? null
                        : () => viewModel.moveModuleBy(id, 1),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Tooltip(
                      message: 'ลากเพื่อจัดลำดับ',
                      child: SizedBox.square(
                        dimension: 48,
                        child: Icon(Icons.drag_handle_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (viewModel.config.showCountdown) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตั้งค่านับถอยหลัง (Countdown)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _countdownTitleController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่องาน / วันสำคัญ',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: viewModel.setCountdownTitle,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final current = DateTime.tryParse(viewModel.config.countdownDate ?? '') ??
                        DateTime.now().add(const Duration(days: 30));
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: current,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      viewModel.setCountdownDate(
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
                      );
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    viewModel.config.countdownDate != null
                        ? 'เป้าหมาย: ${viewModel.config.countdownDate}'
                        : 'เลือกวันเป้าหมาย',
                  ),
                ),
              ],
            ),
          ),
        ],
        if (viewModel.config.showPinnedNote) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อความโน้ตปักหมุด',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteTextController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'พิมพ์โน้ตเตือนใจที่อยากให้แสดงบนล็อกสกรีน…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: viewModel.setPinnedNoteText,
                ),
                const SizedBox(height: 10),
                Text(
                  'สไตล์กระดาษโน้ต',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'plain', label: Text('เรียบ')),
                    ButtonSegment(value: 'lined', label: Text('มีเส้น')),
                    ButtonSegment(value: 'grid', label: Text('ตาราง')),
                    ButtonSegment(value: 'tape', label: Text('เทปแปะ')),
                  ],
                  selected: {viewModel.config.paperStyle},
                  onSelectionChanged: (value) =>
                      viewModel.setPaperStyle(value.first),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('จำนวนงานที่แสดง', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 4, label: Text('4')),
            ButtonSegment(value: 6, label: Text('6')),
          ],
          selected: {viewModel.config.taskLimit},
          onSelectionChanged: (value) => viewModel.setTaskLimit(value.first),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.blur_on_rounded),
          title: const Text('ลดความเด่นงานที่เลยกำหนดแล้ว'),
          subtitle: const Text(
            'แสดงงานที่ผ่านไปแล้วด้วยสีจางลง เพื่อโฟกัสงานปัจจุบัน',
          ),
          value: viewModel.config.dimPastEvents,
          onChanged: viewModel.setDimPastEvents,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.sync_rounded),
          title: const Text('อัปเดตอัตโนมัติ'),
          subtitle: const Text(
            'อัปเดตเมื่อเพิ่ม แก้ไข หรือทำงานเสร็จบน Android',
          ),
          value: viewModel.config.autoUpdate,
          onChanged: viewModel.setAutoUpdate,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              viewModel.reset();
              _countdownTitleController.text = viewModel.config.countdownTitle;
              _noteTextController.text = viewModel.config.pinnedNoteText;
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('คืนค่าเริ่มต้น'),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: theme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Android ตั้งภาพให้โดยตรง ส่วน iPhone จะเปิดเมนูแชร์ของระบบเพื่อบันทึกภาพ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: theme.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  (IconData, String, bool, ValueChanged<bool>) _moduleDefinition(
    String id,
    LockScreenViewModel model,
  ) => switch (id) {
    'clock' => (
      Icons.schedule_rounded,
      'วันที่และเวลา',
      model.config.showClock,
      model.setShowClock,
    ),
    'countdown' => (
      Icons.hourglass_top_rounded,
      'นับถอยหลังวันสำคัญ',
      model.config.showCountdown,
      model.setShowCountdown,
    ),
    'note' => (
      Icons.push_pin_rounded,
      'บันทึกปักหมุด',
      model.config.showPinnedNote,
      model.setShowPinnedNote,
    ),
    'progress' => (
      Icons.donut_large_rounded,
      'ความคืบหน้าของปี',
      model.config.showProgress,
      model.setShowProgress,
    ),
    'year_progress' => (
      Icons.apps_rounded,
      '🌱 จุด 365 วัน (Year Progress)',
      model.config.showYearProgress,
      model.setShowYearProgress,
    ),
    'tasks' => (
      Icons.checklist_rounded,
      'งานสำคัญวันนี้',
      model.config.showTasks,
      model.setShowTasks,
    ),
    _ => (
      Icons.calendar_view_week_rounded,
      'ปฏิทินรายสัปดาห์',
      model.config.showCalendar,
      model.setShowCalendar,
    ),
  };
}

class _ModuleSwitch extends StatelessWidget {
  const _ModuleSwitch({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: onChanged,
    controlAffinity: ListTileControlAffinity.trailing,
    secondary: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon), ?trailing],
    ),
  );
}
