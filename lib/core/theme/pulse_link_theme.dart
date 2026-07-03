import 'package:flutter/material.dart';

import '../enums/app_mode.dart';

class PulseLinkTheme {
  const PulseLinkTheme._();

  static const primaryRed = Color(0xFFE31837);
  static const alertRed = Color(0xFFFF2D45);
  static const deepBloodRed = Color(0xFF8A0012);
  static const pulseNavy = Color(0xFF082348);
  static const deepNavy = Color(0xFF03162E);
  static const dailyBackground = Color(0xFF061A33);
  static const dailyLightBackground = Color(0xFFF8FAFC);
  static const cardBackground = Color(0xFF0B2747);
  static const cardLightBackground = Color(0xFFFFFFFF);
  static const mutedText = Color(0xFFB8C4D6);
  static const mutedTextLight = Color(0xFF64748B);
  static const successGreen = Color(0xFF10B981);

  static ThemeData themeForMode(
    AppMode mode, {
    required Brightness brightness,
  }) {
    final seed = mode == AppMode.sos ? alertRed : primaryRed;
    final isDark = brightness == Brightness.dark;
    final scaffold = isDark ? dailyBackground : dailyLightBackground;
    final surface = isDark ? cardBackground : cardLightBackground;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? mutedText : mutedTextLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        primary: seed,
        surface: cardBackground,
      ).copyWith(
        primary: seed,
        secondary: isDark ? pulseNavy : const Color(0xFF0F3B73),
        surface: surface,
        onSurface: onSurface,
        outline: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
      ),
      fontFamily: 'BeVietnamPro',
      fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
      textTheme: _textTheme(onSurface, muted),
      primaryTextTheme: _textTheme(onSurface, muted),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: seed.withOpacity(isDark ? 0.18 : 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'BeVietnamPro',
            fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
            color: onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? seed : muted);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? cardBackground : const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color scaffoldColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color textColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color mutedColor(BuildContext context) {
    return isDark(context) ? mutedText : mutedTextLight;
  }

  static Color subtleBorderColor(BuildContext context) {
    return isDark(context)
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFE2E8F0);
  }

  static TextTheme _textTheme(Color textColor, Color mutedColor) {
    const family = 'BeVietnamPro';

    return TextTheme(
      displayLarge: _textStyle(family, textColor, 48, FontWeight.w800, 1.05),
      displayMedium: _textStyle(family, textColor, 40, FontWeight.w800, 1.08),
      displaySmall: _textStyle(family, textColor, 34, FontWeight.w800, 1.1),
      headlineLarge: _textStyle(family, textColor, 30, FontWeight.w800, 1.15),
      headlineMedium: _textStyle(family, textColor, 26, FontWeight.w800, 1.18),
      headlineSmall: _textStyle(family, textColor, 22, FontWeight.w700, 1.2),
      titleLarge: _textStyle(family, textColor, 20, FontWeight.w700, 1.25),
      titleMedium: _textStyle(family, textColor, 16, FontWeight.w600, 1.3),
      titleSmall: _textStyle(family, textColor, 14, FontWeight.w600, 1.35),
      bodyLarge: _textStyle(family, textColor, 16, FontWeight.w400, 1.45),
      bodyMedium: _textStyle(family, textColor, 14, FontWeight.w400, 1.45),
      bodySmall: _textStyle(family, mutedColor, 12, FontWeight.w400, 1.4),
      labelLarge: _textStyle(family, textColor, 14, FontWeight.w600, 1.2),
      labelMedium: _textStyle(family, textColor, 12, FontWeight.w600, 1.2),
      labelSmall: _textStyle(family, mutedColor, 11, FontWeight.w600, 1.2),
    );
  }

  static TextStyle _textStyle(
    String family,
    Color color,
    double size,
    FontWeight weight,
    double height,
  ) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
    );
  }
}
