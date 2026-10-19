import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/moss_haptics.dart';

enum AddActionType { task, event, note }

class AddActionSheet extends StatelessWidget {
  const AddActionSheet({super.key});

  static Future<AddActionType?> show(BuildContext context) {
    return showModalBottomSheet<AddActionType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Title
          Text(
            'เพิ่ม',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24),
          // 3 Action items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionTile(
                icon: Icons.check_circle_outline_rounded,
                fillColor: Color(0xFF3B1E22),
                iconColor: AppColors.quadrant1,
                label: 'งาน',
                onTap: () {
                  MossHaptics.selection();
                  Navigator.of(context).pop(AddActionType.task);
                },
              ),
              _ActionTile(
                icon: Icons.calendar_today_rounded,
                fillColor: Color(0xFF1B2A42),
                iconColor: AppColors.quadrant2,
                label: 'เหตุการณ์',
                onTap: () {
                  MossHaptics.selection();
                  Navigator.of(context).pop(AddActionType.event);
                },
              ),
              _ActionTile(
                icon: Icons.feed_outlined,
                fillColor: Color(0xFF3A3118),
                iconColor: AppColors.quadrant3,
                label: 'โน้ต',
                onTap: () {
                  MossHaptics.selection();
                  Navigator.of(context).pop(AddActionType.note);
                },
              ),
            ],
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.fillColor,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color fillColor;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
