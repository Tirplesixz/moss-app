import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  final Future<void> Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                'งานด่วนเข้า\nก็ยังไม่ลน',
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 40,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ใส่งานพร้อมเวลาที่ต้องใช้ Moss จะหาช่วงว่างและจัดวันนี้ให้ใหม่ โดยไม่แตะเวลาที่คุณล็อกไว้',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 30),
              const _Benefit(
                icon: Icons.bolt_rounded,
                title: 'พิมพ์งานด่วนได้ทันที',
              ),
              const _Benefit(
                icon: Icons.calendar_month_rounded,
                title: 'เห็นว่างานไหนถูกขยับก่อนยืนยัน',
              ),
              const _Benefit(
                icon: Icons.undo_rounded,
                title: 'เปลี่ยนใจแล้วเลิกทำได้',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onComplete,
                  child: const Text(
                    'เริ่มจัดวันนี้',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'ข้อมูลทั้งหมดอยู่บนเครื่องของคุณ',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.nowFill,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: theme.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
