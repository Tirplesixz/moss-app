import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_primitives.dart';

class OnboardingScreen extends StatelessWidget {
  final Future<void> Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              MossSpacing.x6,
              MossSpacing.x8,
              MossSpacing.x6,
              MossSpacing.x6,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - MossSpacing.x8,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MossSpacing.x12,
                      height: MossSpacing.x12,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(MossRadii.lg),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.onPrimary,
                        size: MossIconSizes.lg,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'งานด่วนเข้า\nก็ยังไม่ลน',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: MossSpacing.x4),
                    Text(
                      'ใส่งานพร้อมเวลาที่ต้องใช้ Moss จะหาช่วงว่างและจัดวันนี้ให้ใหม่ โดยไม่แตะเวลาที่คุณล็อกไว้',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: MossSpacing.x8),
                    const _Benefit(
                      icon: Icons.bolt_rounded,
                      title: 'พิมพ์งานด่วนได้ทันที',
                    ),
                    const _Benefit(
                      icon: Icons.calendar_month_rounded,
                      title: 'ซิงก์นัดหมายกับปฏิทินในเครื่องอัตโนมัติ',
                    ),
                    const _Benefit(
                      icon: Icons.auto_awesome_motion_rounded,
                      title: 'เห็นว่างานไหนถูกขยับก่อนยืนยัน',
                    ),
                    const _Benefit(
                      icon: Icons.undo_rounded,
                      title: 'เปลี่ยนใจแล้วเลิกทำได้',
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onComplete,
                        child: const Text('เริ่มจัดวันนี้'),
                      ),
                    ),
                    const SizedBox(height: MossSpacing.x2),
                    Center(
                      child: Text(
                        'ข้อมูลทั้งหมดอยู่บนเครื่องของคุณ',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: theme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Benefit({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    final components = context.mossComponents;
    return Padding(
      padding: const EdgeInsets.only(bottom: MossSpacing.x3),
      child: Row(
        children: [
          Container(
            width: MossSpacing.x10,
            height: MossSpacing.x10,
            decoration: BoxDecoration(
              color: components.fixedTaskSurface,
              borderRadius: BorderRadius.circular(MossRadii.md),
            ),
            child: Icon(icon, color: theme.primary, size: MossIconSizes.md),
          ),
          const SizedBox(width: MossSpacing.x3),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}
