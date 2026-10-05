import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/utils/thai_date_formatter.dart';

/// Top header showing the small date and the section title "ตอนนี้"
/// as specified in PLAN.md Section 7.1.
class TodayHeader extends StatelessWidget {
  final DateTime date;

  const TodayHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('วันนี้', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: MossSpacing.x1),
        Text(
          ThaiDateFormatter.formatFullDate(date),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: theme.textMuted),
        ),
      ],
    );
  }
}
