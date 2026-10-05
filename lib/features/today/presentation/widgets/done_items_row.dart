import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Displays completed tasks collapsed to one muted line as specified in PLAN.md Section 7.1.
class DoneItemsRow extends StatefulWidget {
  final List<String> items;

  const DoneItemsRow({super.key, required this.items});

  @override
  State<DoneItemsRow> createState() => _DoneItemsRowState();
}

class _DoneItemsRowState extends State<DoneItemsRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = context.mossTheme;

    // Collapsed: show latest done item or summary
    final latestItem = widget.items.last;
    final totalCount = widget.items.length;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: totalCount > 1
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: theme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latestItem,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textMuted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: theme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (totalCount > 1) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+${totalCount - 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textMuted,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: theme.textMuted,
                  ),
                ],
              ],
            ),
          ),
          if (_isExpanded && totalCount > 1) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...widget.items
                .take(totalCount - 1)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textMuted,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: theme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
