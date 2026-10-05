import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/theme/moss_motion.dart';

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
      margin: const EdgeInsets.only(bottom: MossSpacing.x3),
      padding: const EdgeInsets.symmetric(vertical: MossSpacing.x1),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: InkWell(
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
                    size: MossIconSizes.md,
                    color: theme.success,
                  ),
                  const SizedBox(width: MossSpacing.x2),
                  Expanded(
                    child: Text(
                      latestItem,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme.textMuted,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: theme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (totalCount > 1) ...[
                    const SizedBox(width: MossSpacing.x2),
                    Text(
                      '+${totalCount - 1}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: theme.textMuted),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: MossMotion.duration(
                        context,
                        MossMotion.standard,
                      ),
                      curve: MossMotion.stateCurve,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: MossIconSizes.md,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isExpanded && totalCount > 1) ...[
            const SizedBox(height: MossSpacing.x2),
            const Divider(height: 1),
            const SizedBox(height: MossSpacing.x2),
            ...widget.items
                .take(totalCount - 1)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: MossSpacing.x1,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: MossSpacing.x6),
                        Expanded(
                          child: Text(
                            item,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
