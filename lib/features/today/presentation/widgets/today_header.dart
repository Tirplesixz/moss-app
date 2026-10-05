import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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
        Text(
          'วันนี้',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: theme.onBackground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          ThaiDateFormatter.formatFullDate(date),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.textMuted,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
