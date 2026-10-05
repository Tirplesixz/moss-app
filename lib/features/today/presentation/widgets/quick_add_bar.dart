import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/moss_motion.dart';

/// Bottom quick-add bar as specified in PLAN.md Section 7.1.
class QuickAddBar extends StatefulWidget {
  final Future<void> Function(String) onAddTask;
  final void Function(String? prefillTitle)? onOpenManualForm;

  const QuickAddBar({
    super.key,
    required this.onAddTask,
    this.onOpenManualForm,
  });

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _focusNode.unfocus();
      setState(() => _isSubmitting = true);
      try {
        await widget.onAddTask(text);
        _controller.clear();
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      widget.onOpenManualForm?.call(null);
    }
  }

  void _handleManualOpen() {
    final text = _controller.text.trim();
    widget.onOpenManualForm?.call(text.isNotEmpty ? text : null);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;

    return Container(
      padding: EdgeInsets.only(
        left: MossSpacing.x4,
        right: MossSpacing.x4,
        top: MossSpacing.x2,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? MossSpacing.x3
            : MediaQuery.of(context).padding.bottom + MossSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.borderSubtle)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              // Text Input Field
              Expanded(
                child: ListenableBuilder(
                  listenable: _focusNode,
                  builder: (context, child) => AnimatedContainer(
                    duration: MossMotion.duration(context, MossMotion.fast),
                    curve: MossMotion.stateCurve,
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MossSpacing.x3,
                    ),
                    decoration: BoxDecoration(
                      color: components.inputSurface,
                      borderRadius: BorderRadius.circular(MossRadii.md),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? components.inputFocusBorder
                            : components.inputBorder,
                        width: _focusNode.hasFocus ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            enabled: !_isSubmitting,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSubmit(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'เพิ่มงานด่วน...',
                              hintStyle: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: theme.textMuted),
                              filled: false,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: MossMotion.duration(
                            context,
                            MossMotion.fast,
                          ),
                          child: _isSubmitting
                              ? Semantics(
                                  key: const ValueKey('loading'),
                                  liveRegion: true,
                                  label: 'กำลังจัดตารางใหม่',
                                  child: SizedBox(
                                    width: MossIconSizes.md,
                                    height: MossIconSizes.md,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primary,
                                    ),
                                  ),
                                )
                              : Tooltip(
                                  key: const ValueKey('microphone'),
                                  message:
                                      'สั่งด้วยเสียง (จะเปิดให้ใช้งานในเวอร์ชันถัดไป)',
                                  child: ExcludeSemantics(
                                    child: Icon(
                                      Icons.mic_none_rounded,
                                      size: MossIconSizes.md,
                                      color: theme.textMuted.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: MossSpacing.x2),

              Semantics(
                button: true,
                enabled: !_isSubmitting,
                label: _isSubmitting ? 'กำลังเพิ่มงานด่วน' : 'เพิ่มงานด่วน',
                child: Material(
                  color: _isSubmitting ? theme.surfaceMuted : theme.primary,
                  borderRadius: BorderRadius.circular(MossRadii.md),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(MossRadii.md),
                    onTap: _isSubmitting ? null : _handleSubmit,
                    onLongPress: _isSubmitting ? null : _handleManualOpen,
                    child: SizedBox(
                      width: MossSpacing.x12,
                      height: MossSpacing.x12,
                      child: AnimatedSwitcher(
                        duration: MossMotion.duration(context, MossMotion.fast),
                        child: _isSubmitting
                            ? SizedBox(
                                key: const ValueKey('button-loading'),
                                width: MossIconSizes.md,
                                height: MossIconSizes.md,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.textMuted,
                                ),
                              )
                            : Icon(
                                Icons.add_rounded,
                                key: const ValueKey('button-add'),
                                color: theme.onPrimary,
                                size: MossIconSizes.lg,
                              ),
                      ),
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
}
