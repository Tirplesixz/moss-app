import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom quick-add bar as specified in PLAN.md Section 7.1.
class QuickAddBar extends StatefulWidget {
  final ValueChanged<String> onAddTask;
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

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAddTask(text);
      _controller.clear();
      _focusNode.unfocus();
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

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 12
            : MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: theme.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text Input Field
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSubmit(),
                      style: TextStyle(fontSize: 14, color: theme.onBackground),
                      decoration: InputDecoration(
                        hintText: 'งานอะไรเข้ามา...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: theme.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // Mic button: disabled/hidden until voice is built (PLAN.md Section 7.1)
                  Tooltip(
                    message: 'สั่งด้วยเสียง (จะเปิดให้ใช้งานในเวอร์ชันถัดไป)',
                    child: Icon(
                      Icons.mic_none_rounded,
                      size: 20,
                      color: theme.textMuted.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Primary Add Button (+)
          Material(
            color: theme.primary,
            borderRadius: BorderRadius.circular(14),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _handleSubmit,
              onLongPress: _handleManualOpen,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
