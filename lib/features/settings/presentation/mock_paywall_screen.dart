import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_primitives.dart';

class MockPaywallScreen extends ConsumerWidget {
  const MockPaywallScreen({super.key});

  Future<void> _recordInterest(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(settingsRepositoryProvider);
    final settings = await repository.getSettings();
    await repository.updateSettings(
      settings.copyWith(
        paywallInterestCount: settings.paywallInterestCount + 1,
      ),
    );
    await ref.read(eventLogRepositoryProvider).track('mock_subscribe_tapped');
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ขอบคุณที่สนใจ'),
        content: const Text(
          'แพ็กเกจนี้ยังไม่เปิดขาย ตอนนี้ทุกฟีเจอร์ในรุ่นทดสอบยังใช้ฟรี',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.mossTheme;
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('Moss Plus')),
      body: Padding(
        padding: const EdgeInsets.all(MossSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'วันที่แน่นแค่ไหน\nก็ยังคุมได้',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: MossSpacing.x6),
            const _Feature(text: 'จัดตารางงานด่วนได้ไม่จำกัด'),
            const _Feature(text: 'เชื่อมปฏิทินและใช้วิดเจ็ต — เร็ว ๆ นี้'),
            const _Feature(text: 'ช่วยแปลงข้อความเป็นงาน — เร็ว ๆ นี้'),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MossSpacing.x5),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(MossRadii.lg),
                border: Border.all(color: theme.borderSubtle),
              ),
              child: const Column(
                children: [
                  Text(
                    '฿129 / เดือน',
                    style: TextStyle(
                      fontSize: MossTypeSizes.heading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: MossSpacing.x1),
                  Text('ราคาทดลอง ยังไม่มีการเรียกเก็บเงินจริง'),
                ],
              ),
            ),
            const SizedBox(height: MossSpacing.x4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _recordInterest(context, ref),
                child: const Text('สนใจ Moss Plus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String text;
  const _Feature({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: MossSpacing.x4),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: theme.primary),
          const SizedBox(width: MossSpacing.x3),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
