import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/moss_motion.dart';
import '../utils/moss_haptics.dart';

/// A quick-action Theme Toggle Button with smooth micro-animations.
/// Cycles between System, Light, and Dark modes on tap, or shows a quick picker on long press.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = context.mossTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final IconData icon;
    final Color iconColor;
    final String label;

    switch (themeMode) {
      case ThemeMode.system:
        icon = isDark
            ? Icons.brightness_auto_rounded
            : Icons.brightness_auto_rounded;
        iconColor = isDark ? const Color(0xFF9E86FF) : const Color(0xFF6B4EFF);
        label = 'โหมดระบบ';
        break;
      case ThemeMode.light:
        icon = Icons.light_mode_rounded;
        iconColor = const Color(0xFFF5A623);
        label = 'โหมดสว่าง';
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_rounded;
        iconColor = const Color(0xFF9E86FF);
        label = 'โหมดมืด';
        break;
    }

    return Tooltip(
      message: 'เปลี่ยนธีม ($label)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: () {
            MossHaptics.selection();
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
          onLongPress: () {
            MossHaptics.selection();
            _showThemeBottomSheet(context, ref);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: theme.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: theme.borderSubtle, width: 1),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: MossMotion.duration(
                  context,
                  const Duration(milliseconds: 180),
                ),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: Tween<double>(
                      begin: 0.8,
                      end: 1.0,
                    ).animate(animation),
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey<ThemeMode>(themeMode),
                  color: iconColor,
                  size: size * 0.52,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    final theme = context.mossTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'เลือกลักษณะ (Theme)',
              style: TextStyle(
                color: theme.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _ThemeOptionTile(
              icon: Icons.brightness_auto_rounded,
              title: 'ตามระบบ (System)',
              subtitle: 'ปรับสว่างหรือมืดตามการตั้งค่าของอุปกรณ์',
              isSelected: currentMode == ThemeMode.system,
              onTap: () {
                MossHaptics.selection();
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              },
            ),
            _ThemeOptionTile(
              icon: Icons.light_mode_rounded,
              title: 'สว่าง (Light)',
              subtitle: 'พื้นหลังขาวและสบายตาในเวลากลางวัน',
              isSelected: currentMode == ThemeMode.light,
              onTap: () {
                MossHaptics.selection();
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              },
            ),
            _ThemeOptionTile(
              icon: Icons.dark_mode_rounded,
              title: 'มืด (Dark)',
              subtitle: 'โทนมืดประหยัดพลังงานและถนอมสายตา',
              isSelected: currentMode == ThemeMode.dark,
              onTap: () {
                MossHaptics.selection();
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primary : theme.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? theme.primary : theme.onBackground,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// A segmented 3-way Theme Selector matching Apple HIG aesthetic.
class ThemeSegmentedSelector extends ConsumerWidget {
  const ThemeSegmentedSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = context.mossTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Row(
        children: [
          _SegmentItem(
            icon: Icons.brightness_auto_rounded,
            label: 'ระบบ',
            isSelected: themeMode == ThemeMode.system,
            onTap: () {
              MossHaptics.selection();
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.system);
            },
          ),
          _SegmentItem(
            icon: Icons.light_mode_rounded,
            label: 'สว่าง',
            isSelected: themeMode == ThemeMode.light,
            onTap: () {
              MossHaptics.selection();
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light);
            },
          ),
          _SegmentItem(
            icon: Icons.dark_mode_rounded,
            label: 'มืด',
            isSelected: themeMode == ThemeMode.dark,
            onTap: () {
              MossHaptics.selection();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.mossTheme;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'ธีม$label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: MossMotion.duration(
              context,
              const Duration(milliseconds: 180),
            ),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? theme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? theme.primary : theme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? theme.onBackground
                        : theme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
