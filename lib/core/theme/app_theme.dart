import 'package:flutter/material.dart';

import 'app_primitives.dart';

/// Semantic color layer. Components consume these roles, never raw colors.
@immutable
class MossThemeExtension extends ThemeExtension<MossThemeExtension> {
  final Color background;
  final Color onBackground;
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color surfaceMuted;
  final Color textMuted;
  final Color textSecondary;
  final Color borderSubtle;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color focusRing;
  final Color urgentAccent;

  const MossThemeExtension({
    required this.background,
    required this.onBackground,
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.surfaceMuted,
    required this.textMuted,
    required this.textSecondary,
    required this.borderSubtle,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.focusRing,
    required this.urgentAccent,
  });

  static const light = MossThemeExtension(
    background: MossPrimitives.neutral50,
    onBackground: MossPrimitives.neutral900,
    primary: MossPrimitives.violet600,
    onPrimary: MossPrimitives.white,
    surface: MossPrimitives.white,
    surfaceMuted: MossPrimitives.neutral100,
    textMuted: MossPrimitives.neutral600,
    textSecondary: MossPrimitives.neutral700,
    borderSubtle: MossPrimitives.neutral300,
    divider: MossPrimitives.neutral200,
    success: MossPrimitives.mint700,
    warning: MossPrimitives.amber500,
    error: MossPrimitives.red500,
    info: MossPrimitives.blue500,
    focusRing: MossPrimitives.violet600,
    urgentAccent: MossPrimitives.orange500,
  );

  static const dark = MossThemeExtension(
    background: Color(0xFF0D0F14),
    onBackground: Color(0xFFF9FAFB),
    primary: MossPrimitives.violet400,
    onPrimary: Color(0xFFFFFFFF),
    surface: Color(0xFF161922),
    surfaceMuted: Color(0xFF1E2330),
    textMuted: Color(0xFF9AA3B3),
    textSecondary: Color(0xFFB8BFCC),
    borderSubtle: Color(0xFF343B4C),
    divider: Color(0xFF2B3140),
    success: Color(0xFF30D158),
    warning: Color(0xFFFFD60A),
    error: Color(0xFFFF453A),
    info: Color(0xFF0A84FF),
    focusRing: MossPrimitives.violet400,
    urgentAccent: Color(0xFFFF453A),
  );

  // Compatibility aliases while components migrate to the component layer.
  Color get nowFill => MossComponentTheme.forBrightness(
    background.computeLuminance() < 0.2 ? Brightness.dark : Brightness.light,
  ).activeTaskSurface;
  Color get nowBorder => MossComponentTheme.forBrightness(
    background.computeLuminance() < 0.2 ? Brightness.dark : Brightness.light,
  ).activeTaskBorder;
  Color get cardBackground => surface;

  @override
  MossThemeExtension copyWith({
    Color? background,
    Color? onBackground,
    Color? primary,
    Color? onPrimary,
    Color? surface,
    Color? surfaceMuted,
    Color? textMuted,
    Color? textSecondary,
    Color? borderSubtle,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? focusRing,
    Color? urgentAccent,
  }) {
    return MossThemeExtension(
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textMuted: textMuted ?? this.textMuted,
      textSecondary: textSecondary ?? this.textSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      focusRing: focusRing ?? this.focusRing,
      urgentAccent: urgentAccent ?? this.urgentAccent,
    );
  }

  @override
  MossThemeExtension lerp(ThemeExtension<MossThemeExtension>? other, double t) {
    if (other is! MossThemeExtension) return this;
    return MossThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      urgentAccent: Color.lerp(urgentAccent, other.urgentAccent, t)!,
    );
  }
}

/// Component layer for page-specific surfaces and control states.
@immutable
class MossComponentTheme extends ThemeExtension<MossComponentTheme> {
  final Color taskSurface;
  final Color taskBorder;
  final Color fixedTaskSurface;
  final Color fixedTaskBorder;
  final Color activeTaskSurface;
  final Color activeTaskBorder;
  final Color inputSurface;
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color urgentSurface;
  final Color urgentBorder;
  final Color navigationSelectedSurface;
  final Color customerSurface;
  final Color customerAccent;
  final Color internalSurface;
  final Color internalAccent;
  final Color projectSurface;
  final Color projectAccent;

  const MossComponentTheme({
    required this.taskSurface,
    required this.taskBorder,
    required this.fixedTaskSurface,
    required this.fixedTaskBorder,
    required this.activeTaskSurface,
    required this.activeTaskBorder,
    required this.inputSurface,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.urgentSurface,
    required this.urgentBorder,
    required this.navigationSelectedSurface,
    required this.customerSurface,
    required this.customerAccent,
    required this.internalSurface,
    required this.internalAccent,
    required this.projectSurface,
    required this.projectAccent,
  });

  static const light = MossComponentTheme(
    taskSurface: MossPrimitives.neutral50,
    taskBorder: MossPrimitives.neutral450,
    fixedTaskSurface: MossPrimitives.mint50,
    fixedTaskBorder: MossPrimitives.mint500,
    activeTaskSurface: MossPrimitives.violet50,
    activeTaskBorder: MossPrimitives.violet600,
    inputSurface: MossPrimitives.neutral50,
    inputBorder: MossPrimitives.neutral450,
    inputFocusBorder: MossPrimitives.violet600,
    urgentSurface: MossPrimitives.orange100,
    urgentBorder: MossPrimitives.orange500,
    navigationSelectedSurface: MossPrimitives.violet100,
    customerSurface: MossPrimitives.sky50,
    customerAccent: MossPrimitives.sky600,
    internalSurface: MossPrimitives.mint50,
    internalAccent: MossPrimitives.mint700,
    projectSurface: MossPrimitives.violet50,
    projectAccent: MossPrimitives.violet600,
  );

  static const dark = MossComponentTheme(
    taskSurface: Color(0xFF161922),
    taskBorder: Color(0xFF242A38),
    fixedTaskSurface: Color(0xFF1E2330),
    fixedTaskBorder: Color(0xFF0A84FF),
    activeTaskSurface: Color(0xFF1E2330),
    activeTaskBorder: Color(0xFF0A84FF),
    inputSurface: Color(0xFF161922),
    inputBorder: Color(0xFF242A38),
    inputFocusBorder: Color(0xFF0A84FF),
    urgentSurface: Color(0xFF241618),
    urgentBorder: Color(0xFFFF453A),
    navigationSelectedSurface: Color(0xFF282D3D),
    customerSurface: Color(0xFF161922),
    customerAccent: Color(0xFF0A84FF),
    internalSurface: Color(0xFF161922),
    internalAccent: Color(0xFF30D158),
    projectSurface: Color(0xFF161922),
    projectAccent: Color(0xFF0A84FF),
  );

  static MossComponentTheme forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  MossComponentTheme copyWith({
    Color? taskSurface,
    Color? taskBorder,
    Color? fixedTaskSurface,
    Color? fixedTaskBorder,
    Color? activeTaskSurface,
    Color? activeTaskBorder,
    Color? inputSurface,
    Color? inputBorder,
    Color? inputFocusBorder,
    Color? urgentSurface,
    Color? urgentBorder,
    Color? navigationSelectedSurface,
    Color? customerSurface,
    Color? customerAccent,
    Color? internalSurface,
    Color? internalAccent,
    Color? projectSurface,
    Color? projectAccent,
  }) {
    return MossComponentTheme(
      taskSurface: taskSurface ?? this.taskSurface,
      taskBorder: taskBorder ?? this.taskBorder,
      fixedTaskSurface: fixedTaskSurface ?? this.fixedTaskSurface,
      fixedTaskBorder: fixedTaskBorder ?? this.fixedTaskBorder,
      activeTaskSurface: activeTaskSurface ?? this.activeTaskSurface,
      activeTaskBorder: activeTaskBorder ?? this.activeTaskBorder,
      inputSurface: inputSurface ?? this.inputSurface,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusBorder: inputFocusBorder ?? this.inputFocusBorder,
      urgentSurface: urgentSurface ?? this.urgentSurface,
      urgentBorder: urgentBorder ?? this.urgentBorder,
      navigationSelectedSurface:
          navigationSelectedSurface ?? this.navigationSelectedSurface,
      customerSurface: customerSurface ?? this.customerSurface,
      customerAccent: customerAccent ?? this.customerAccent,
      internalSurface: internalSurface ?? this.internalSurface,
      internalAccent: internalAccent ?? this.internalAccent,
      projectSurface: projectSurface ?? this.projectSurface,
      projectAccent: projectAccent ?? this.projectAccent,
    );
  }

  @override
  MossComponentTheme lerp(ThemeExtension<MossComponentTheme>? other, double t) {
    if (other is! MossComponentTheme) return this;
    return MossComponentTheme(
      taskSurface: Color.lerp(taskSurface, other.taskSurface, t)!,
      taskBorder: Color.lerp(taskBorder, other.taskBorder, t)!,
      fixedTaskSurface: Color.lerp(
        fixedTaskSurface,
        other.fixedTaskSurface,
        t,
      )!,
      fixedTaskBorder: Color.lerp(fixedTaskBorder, other.fixedTaskBorder, t)!,
      activeTaskSurface: Color.lerp(
        activeTaskSurface,
        other.activeTaskSurface,
        t,
      )!,
      activeTaskBorder: Color.lerp(
        activeTaskBorder,
        other.activeTaskBorder,
        t,
      )!,
      inputSurface: Color.lerp(inputSurface, other.inputSurface, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocusBorder: Color.lerp(
        inputFocusBorder,
        other.inputFocusBorder,
        t,
      )!,
      urgentSurface: Color.lerp(urgentSurface, other.urgentSurface, t)!,
      urgentBorder: Color.lerp(urgentBorder, other.urgentBorder, t)!,
      navigationSelectedSurface: Color.lerp(
        navigationSelectedSurface,
        other.navigationSelectedSurface,
        t,
      )!,
      customerSurface: Color.lerp(customerSurface, other.customerSurface, t)!,
      customerAccent: Color.lerp(customerAccent, other.customerAccent, t)!,
      internalSurface: Color.lerp(internalSurface, other.internalSurface, t)!,
      internalAccent: Color.lerp(internalAccent, other.internalAccent, t)!,
      projectSurface: Color.lerp(projectSurface, other.projectSurface, t)!,
      projectAccent: Color.lerp(projectAccent, other.projectAccent, t)!,
    );
  }
}

extension BuildContextThemeExtension on BuildContext {
  MossThemeExtension get mossTheme =>
      Theme.of(this).extension<MossThemeExtension>() ??
      MossThemeExtension.light;

  MossComponentTheme get mossComponents =>
      Theme.of(this).extension<MossComponentTheme>() ??
      MossComponentTheme.forBrightness(Theme.of(this).brightness);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    semantic: MossThemeExtension.light,
    components: MossComponentTheme.light,
  );

  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    semantic: MossThemeExtension.dark,
    components: MossComponentTheme.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required MossThemeExtension semantic,
    required MossComponentTheme components,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: semantic.primary,
      onPrimary: semantic.onPrimary,
      primaryContainer: components.navigationSelectedSurface,
      onPrimaryContainer: semantic.primary,
      secondary: semantic.primary,
      onSecondary: semantic.onPrimary,
      secondaryContainer: components.navigationSelectedSurface,
      onSecondaryContainer: semantic.primary,
      error: semantic.error,
      onError: brightness == Brightness.dark
          ? MossPrimitives.neutral950
          : MossPrimitives.white,
      surface: semantic.surface,
      onSurface: semantic.onBackground,
      outline: semantic.textMuted,
      outlineVariant: semantic.borderSubtle,
      surfaceContainerLowest: semantic.background,
      surfaceContainerLow: semantic.surfaceMuted,
      surfaceContainer: semantic.surfaceMuted,
      surfaceContainerHigh: semantic.surfaceMuted,
      surfaceContainerHighest: semantic.surfaceMuted,
    );

    final textTheme = TextTheme(
      displaySmall: TextStyle(
        color: semantic.onBackground,
        fontWeight: FontWeight.w700,
        fontSize: MossTypeSizes.display,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        color: semantic.onBackground,
        fontWeight: FontWeight.w700,
        fontSize: MossTypeSizes.heading,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: semantic.onBackground,
        fontWeight: FontWeight.w700,
        fontSize: MossTypeSizes.titleLarge,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: semantic.onBackground,
        fontWeight: FontWeight.w600,
        fontSize: MossTypeSizes.body,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        color: semantic.onBackground,
        fontSize: MossTypeSizes.body,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: semantic.onBackground,
        fontSize: MossTypeSizes.bodySmall,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: semantic.textMuted,
        fontSize: MossTypeSizes.caption,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: semantic.onBackground,
        fontWeight: FontWeight.w600,
        fontSize: MossTypeSizes.bodySmall,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        color: semantic.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: MossTypeSizes.caption,
        height: 1.3,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'NotoSansThai',
      fontFamilyFallback: const ['Noto Sans', 'Roboto', 'sans-serif'],
      scaffoldBackgroundColor: semantic.background,
      colorScheme: colorScheme,
      extensions: [semantic, components],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: semantic.background,
        foregroundColor: semantic.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: semantic.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MossRadii.md),
          side: BorderSide(color: semantic.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: semantic.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: components.inputSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MossSpacing.x4,
          vertical: MossSpacing.x3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MossRadii.md),
          borderSide: BorderSide(color: components.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MossRadii.md),
          borderSide: BorderSide(color: components.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MossRadii.md),
          borderSide: BorderSide(color: components.inputFocusBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MossRadii.md),
          borderSide: BorderSide(color: semantic.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: semantic.primary,
          foregroundColor: semantic.onPrimary,
          disabledBackgroundColor: semantic.surfaceMuted,
          disabledForegroundColor: semantic.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MossRadii.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MossSpacing.x5,
            vertical: MossSpacing.x3,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: semantic.onBackground,
          side: BorderSide(color: semantic.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MossRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: semantic.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: semantic.onBackground,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 1,
        backgroundColor: brightness == Brightness.dark
            ? MossPrimitives.neutral50
            : MossPrimitives.neutral900,
        foregroundColor: brightness == Brightness.dark
            ? MossPrimitives.neutral900
            : MossPrimitives.white,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: semantic.surface,
        indicatorColor: brightness == Brightness.dark
            ? MossPrimitives.neutral100
            : MossPrimitives.neutral900,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: MossIconSizes.lg,
            color: states.contains(WidgetState.selected)
                ? (brightness == Brightness.dark
                      ? MossPrimitives.neutral900
                      : MossPrimitives.white)
                : semantic.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? semantic.onBackground
                : semantic.textMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: semantic.surface,
        indicatorColor: components.navigationSelectedSurface,
        selectedIconTheme: IconThemeData(color: semantic.primary),
        unselectedIconTheme: IconThemeData(color: semantic.textMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: semantic.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 40)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: MossSpacing.x4),
          ),
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(
            BorderSide(color: semantic.borderSubtle),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? components.navigationSelectedSurface
                : semantic.surfaceMuted;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? semantic.primary
                : semantic.textSecondary;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MossRadii.md),
            ),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: semantic.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: semantic.surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.55),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MossRadii.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? MossPrimitives.neutral100
            : MossPrimitives.neutral900,
        contentTextStyle: TextStyle(
          color: brightness == Brightness.dark
              ? MossPrimitives.neutral900
              : MossPrimitives.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MossRadii.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: semantic.primary,
        linearTrackColor: semantic.surfaceMuted,
      ),
    );
  }
}
