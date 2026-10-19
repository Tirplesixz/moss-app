part of 'add_task_screen.dart';

class _QuadrantBox extends StatelessWidget {
  const _QuadrantBox({
    required this.title,
    required this.activeCorner,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final int
  activeCorner; // 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'จัดเป็น$title',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Duration(milliseconds: 150),
          constraints: BoxConstraints(minHeight: 88),
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 4 Mini Square Dots Grid
              _FourDotsIndicator(
                activeCorner: activeCorner,
                activeColor: accentColor,
              ),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: isSelected
                      ? accentColor
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4 miniature squares representing the 4 quadrants of the Eisenhower Matrix
class _FourDotsIndicator extends StatelessWidget {
  const _FourDotsIndicator({
    required this.activeCorner,
    required this.activeColor,
  });

  final int
  activeCorner; // 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    double size = 6;
    double gap = 3;
    final inactiveColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.64).withValues(alpha: 0.35);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _square(activeCorner == 0 ? activeColor : inactiveColor, size),
            SizedBox(width: gap),
            _square(activeCorner == 1 ? activeColor : inactiveColor, size),
          ],
        ),
        SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _square(activeCorner == 2 ? activeColor : inactiveColor, size),
            SizedBox(width: gap),
            _square(activeCorner == 3 ? activeColor : inactiveColor, size),
          ],
        ),
      ],
    );
  }

  Widget _square(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

/// A single option row in Card 2 with icon, label and trailing widget
class _CardOptionRow extends StatelessWidget {
  const _CardOptionRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.72),
          ),
          SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          trailing,
        ],
      ),
    );
  }
}

/// A pill badge displaying date/time with an optional (x) clear button
class _PillValueBadge extends StatelessWidget {
  const _PillValueBadge({
    required this.text,
    required this.hasValue,
    required this.onClear,
  });

  final String text;
  final bool hasValue;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: hasValue
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasValue
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: hasValue
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: 14,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (hasValue) ...[
            SizedBox(width: 6),
            IconButton(
              tooltip: 'ล้าง$text',
              onPressed: () {
                MossHaptics.light();
                onClear();
              },
              icon: Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

/// iOS-styled modal sheet for picking option (Repeat / Reminder)
class _IosSelectorSheet extends StatelessWidget {
  const _IosSelectorSheet({
    required this.title,
    required this.options,
    required this.selectedOption,
  });

  final String title;
  final List<String> options;
  final String selectedOption;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E2330),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          ...options.map((opt) {
            final isSelected = opt == selectedOption;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                opt,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                MossHaptics.selection();
                Navigator.pop(context, opt);
              },
            );
          }),
        ],
      ),
    );
  }
}
