import 'package:flutter/material.dart';

import 'app_primitives.dart';
import 'app_theme.dart';

/// Visual language for task priority (1 = low, 2 = normal, 3 = high).
///
/// Colour is never the only signal: every level also has a label and icon.
class MossPriority {
  MossPriority._();

  static const int low = 1;
  static const int normal = 2;
  static const int high = 3;

  static String label(int priority) => switch (priority) {
    high => 'สำคัญมาก',
    low => 'ไม่เร่ง',
    _ => 'ปกติ',
  };

  static IconData icon(int priority) => switch (priority) {
    high => Icons.local_fire_department_rounded,
    low => Icons.south_rounded,
    _ => Icons.drag_handle_rounded,
  };

  static Color color(BuildContext context, int priority) {
    final theme = context.mossTheme;
    return switch (priority) {
      high => theme.error,
      low => theme.textMuted,
      _ => theme.info,
    };
  }
}

/// A project's accent + tinted surface.
@immutable
class MossProjectColor {
  const MossProjectColor({required this.accent, required this.surface});

  final Color accent;
  final Color surface;
}

/// Deterministic colour per project name, so the same project is always the
/// same colour on every screen without extra storage.
class MossProjectColors {
  MossProjectColors._();

  static const _light = <Color>[
    MossPrimitives.violet600,
    MossPrimitives.sky600,
    MossPrimitives.mint700,
    MossPrimitives.orange700,
    MossPrimitives.rose700,
  ];

  static const _dark = <Color>[
    MossPrimitives.violet300,
    MossPrimitives.blue300,
    MossPrimitives.mint500,
    MossPrimitives.orange300,
    MossPrimitives.rose300,
  ];

  /// Stable across runs (unlike [String.hashCode] which is not guaranteed).
  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static MossProjectColor of(BuildContext context, String? name) {
    final components = context.mossComponents;
    if (name == null || name.trim().isEmpty) {
      return MossProjectColor(
        accent: components.projectAccent,
        surface: components.projectSurface,
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark ? _dark : _light;
    final accent = palette[_stableHash(name) % palette.length];
    return MossProjectColor(
      accent: accent,
      surface: accent.withValues(alpha: dark ? 0.18 : 0.10),
    );
  }
}

/// Small pill showing a task's priority (hidden for normal priority).
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    if (priority == MossPriority.normal) return const SizedBox.shrink();
    final color = MossPriority.color(context, priority);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MossSpacing.x2,
        vertical: MossSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MossRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MossPriority.icon(priority), size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            MossPriority.label(priority),
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
