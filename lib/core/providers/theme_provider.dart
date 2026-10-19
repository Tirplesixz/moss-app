import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_repository.dart';
import 'database_providers.dart';

/// Manages application-wide ThemeMode (system, light, dark).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier([
    super.initial = ThemeMode.system,
    SettingsRepository? repository,
  ]) : _repository = repository {
    if (repository != null) unawaited(_hydrate());
  }

  final SettingsRepository? _repository;

  Future<void> _hydrate() async {
    try {
      final settings = await _repository!.getSettings();
      state = _fromStorage(settings.appearanceMode);
    } catch (_) {
      // Keep the system preference when persistence is unavailable, such as
      // in a lightweight widget test without a database plugin.
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (state != mode) {
      state = mode;
      unawaited(_persist(mode));
    }
  }

  void toggleTheme() {
    switch (state) {
      case ThemeMode.system:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        setThemeMode(ThemeMode.system);
        break;
    }
  }

  /// Toggles between light and dark directly based on current appearance
  void toggleLightDark(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _persist(ThemeMode mode) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      final settings = await repository.getSettings();
      await repository.updateSettings(
        settings.copyWith(appearanceMode: _toStorage(mode)),
      );
    } catch (_) {
      // The in-memory choice remains usable even if storage is unavailable.
    }
  }

  static ThemeMode _fromStorage(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _toStorage(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(
    ThemeMode.system,
    ref.watch(settingsRepositoryProvider),
  );
});
