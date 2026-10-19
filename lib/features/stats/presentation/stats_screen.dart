import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/moss_haptics.dart';
import '../../lockscreen/data/lockscreen_platform_service.dart';
import '../../today/presentation/today_controller.dart';
import '../domain/weekly_stats.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareRecapCard() async {
    MossHaptics.light();
    setState(() => _isExporting = true);
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      await const LockScreenPlatformService().apply(bytes, saveToGallery: true);
      if (!mounted) return;
      MossHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกภาพสรุปสัปดาห์ลงในเครื่องแล้ว!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถบันทึกภาพได้ในขณะนี้')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final stats = WeeklyStats.calculate(state.allTasks);
    final theme = context.mossTheme;

    final maxCount = stats.last7Days.fold<int>(1, (max, d) => d.count > max ? d.count : max);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('สถิติ & สรุปสัปดาห์'),
        actions: [
          IconButton(
            tooltip: 'แชร์สรุปสัปดาห์',
            icon: _isExporting
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_rounded),
            onPressed: _isExporting ? null : _shareRecapCard,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Top Highlights Row
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFF5A623),
                    title: 'ทำต่อเนื่อง',
                    value: '${stats.streakDays} วัน',
                    subtitle: stats.streakDays > 0 ? 'กำลังรักษาฟอร์มได้ดี!' : 'เริ่มทำต่อเนื่องวันนี้',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: theme.success,
                    title: 'งานที่สำเร็จ',
                    value: '${stats.totalCompleted}',
                    subtitle: 'อัตรา ${(stats.completionRate * 100).round()}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7-Day Completion Bar Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'งานที่สำเร็จในรอบ 7 วัน',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'รวม ${stats.totalCompleted} งาน',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final day in stats.last7Days) ...[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  day.count > 0 ? '${day.count}' : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: day.isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : theme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: ((day.count / maxCount) * 100).clamp(8.0, 100.0),
                                  decoration: BoxDecoration(
                                    color: day.isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : (day.count > 0
                                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                                            : theme.divider),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  day.dayLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
                                    color: day.isToday
                                        ? Theme.of(context).colorScheme.onSurface
                                        : theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (day != stats.last7Days.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
                      const SizedBox(width: 6),
                      Text(
                        'วันที่มีประสิทธิผลสูงสุด: ${stats.bestDayName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quadrant Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สัดส่วนงานตามเมทริกซ์ (Eisenhower)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _QuadrantProgressRow(
                    label: 'Q1 ด่วน & สำคัญ',
                    color: AppColors.quadrant1,
                    count: stats.quadrantCounts[1] ?? 0,
                    total: stats.totalCompleted,
                  ),
                  const SizedBox(height: 10),
                  _QuadrantProgressRow(
                    label: 'Q2 ไม่ด่วน แต่สำคัญ',
                    color: AppColors.quadrant2,
                    count: stats.quadrantCounts[2] ?? 0,
                    total: stats.totalCompleted,
                  ),
                  const SizedBox(height: 10),
                  _QuadrantProgressRow(
                    label: 'Q3 ด่วน แต่ไม่สำคัญ',
                    color: AppColors.quadrant3,
                    count: stats.quadrantCounts[3] ?? 0,
                    total: stats.totalCompleted,
                  ),
                  const SizedBox(height: 10),
                  _QuadrantProgressRow(
                    label: 'Q4 ไม่ด่วน ไม่สำคัญ',
                    color: AppColors.quadrant4,
                    count: stats.quadrantCounts[4] ?? 0,
                    total: stats.totalCompleted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Shareable Weekly Card (RepaintBoundary)
            Text(
              'พรีวิวการ์ดแชร์สรุปสัปดาห์',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _shareCardKey,
              child: _WeeklyShareCard(stats: stats),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isExporting ? null : _shareRecapCard,
              icon: const Icon(Icons.share_rounded),
              label: const Text('บันทึกและแชร์การ์ดสรุปสัปดาห์'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuadrantProgressRow extends StatelessWidget {
  const _QuadrantProgressRow({
    required this.label,
    required this.color,
    required this.count,
    required this.total,
  });

  final String label;
  final Color color;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            Text('$count งาน (${(pct * 100).round()}%)',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _WeeklyShareCard extends StatelessWidget {
  const _WeeklyShareCard({required this.stats});
  final WeeklyStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF203B5E),
            Color(0xFF0F1E33),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MOSS RECAP',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF5A623), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.streakDays} DAYS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'สัปดาห์นี้ทำสำเร็จแล้ว',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.totalCompleted} งาน',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'อัตราความสำเร็จ ${(stats.completionRate * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  stats.bestDayName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep going • ออกแบบวันของคุณด้วย Moss',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
