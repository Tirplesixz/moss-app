import 'package:flutter/material.dart';

import '../../../../core/scheduler/scheduler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_primitives.dart';
import '../../../../core/utils/thai_date_formatter.dart';

class UrgentReplanSheet extends StatelessWidget {
  final UrgentScheduleResult proposal;

  const UrgentReplanSheet({super.key, required this.proposal});

  static Future<bool?> show(
    BuildContext context,
    UrgentScheduleResult proposal,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UrgentReplanSheet(proposal: proposal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final diff = proposal.diff;
    final urgentBlock = diff.added.firstOrNull;
    final hasOverflow = diff.overflow.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      padding: EdgeInsets.fromLTRB(
        MossSpacing.x5,
        MossSpacing.x3,
        MossSpacing.x5,
        MediaQuery.paddingOf(context).bottom + MossSpacing.x5,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MossRadii.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: MossSpacing.x5),
          Container(
            width: MossSpacing.x12,
            height: MossSpacing.x12,
            decoration: BoxDecoration(
              color: theme.nowFill,
              borderRadius: BorderRadius.circular(MossRadii.md),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: theme.primary),
          ),
          const SizedBox(height: MossSpacing.x4),
          Text(
            hasOverflow ? 'วันนี้แน่นกว่าที่คิด' : 'จัดตารางใหม่แล้ว',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: MossSpacing.x2),
          Text(
            hasOverflow
                ? 'มีบางงานที่ยังใส่ไม่ลงก่อนกำหนดส่ง คุณเก็บไว้จัดการต่อได้'
                : 'งานด่วนเข้าแล้วก็ยังทัน นี่คือสิ่งที่จะเปลี่ยน',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: MossSpacing.x5),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (urgentBlock != null)
                    _ChangeRow(
                      icon: Icons.bolt_rounded,
                      color: theme.primary,
                      title: proposal.newTask.title,
                      detail:
                          '${ThaiDateFormatter.formatTime(urgentBlock.startAt.toLocal())}–${ThaiDateFormatter.formatTime(urgentBlock.endAt.toLocal())}',
                    ),
                  ...diff.moved.map(
                    (move) => _ChangeRow(
                      icon: Icons.arrow_forward_rounded,
                      color: theme.textSecondary,
                      title: move.title,
                      detail:
                          '${ThaiDateFormatter.formatTime(move.from.toLocal())} → ${ThaiDateFormatter.formatTime(move.to.toLocal())}',
                    ),
                  ),
                  ...diff.overflow.map(
                    (task) => _ChangeRow(
                      icon: Icons.schedule_rounded,
                      color: theme.urgentAccent,
                      title: task.title,
                      detail: 'ยังไม่มีช่วงเวลาที่พอดี',
                    ),
                  ),
                  if (diff.moved.isEmpty && !hasOverflow)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: MossSpacing.x3,
                      ),
                      child: Text(
                        'ไม่มีงานเดิมถูกขยับ',
                        style: TextStyle(color: theme.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('ทำไมจัดแบบนี้'),
                  content: Text(
                    diff.moved.isEmpty
                        ? 'Moss เจอช่วงว่างที่ใส่งานด่วนได้ โดยไม่ต้องขยับงานเดิม'
                        : 'Moss เรียงงานตามกำหนดส่งก่อน รักษาเวลาที่ล็อกไว้ แล้วขยับเฉพาะงานที่จำเป็น ${diff.moved.length} งาน',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('เข้าใจแล้ว'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(
                Icons.help_outline_rounded,
                size: MossIconSizes.md,
              ),
              label: const Text('ทำไมจัดแบบนี้'),
            ),
          ),
          const SizedBox(height: MossSpacing.x4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                hasOverflow ? 'เก็บแผนนี้ไว้ก่อน' : 'ตกลง ใช้ตารางนี้',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Center(child: Text('กลับไปแก้ไข')),
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  const _ChangeRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: MossSpacing.x2),
      padding: const EdgeInsets.all(MossSpacing.x4),
      decoration: BoxDecoration(
        color: theme.surfaceMuted,
        borderRadius: BorderRadius.circular(MossRadii.md),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: MossIconSizes.md),
          const SizedBox(width: MossSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MossSpacing.x1),
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: theme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
