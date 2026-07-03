import 'package:flutter/material.dart';

enum AppThemePreference {
  light,
  dark,
  system,
}

extension AppThemePreferenceDisplay on AppThemePreference {
  String get label {
    return switch (this) {
      AppThemePreference.light => 'Sáng',
      AppThemePreference.dark => 'Tối',
      AppThemePreference.system => 'Theo máy',
    };
  }

  IconData get icon {
    return switch (this) {
      AppThemePreference.light => Icons.light_mode_outlined,
      AppThemePreference.dark => Icons.dark_mode_outlined,
      AppThemePreference.system => Icons.brightness_auto_outlined,
    };
  }

  ThemeMode get themeMode {
    return switch (this) {
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.system => ThemeMode.system,
    };
  }
}
