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
  static const cardBackground = Color(0xFF0B2747);
  static const mutedText = Color(0xFFB8C4D6);
  static const successGreen = Color(0xFF10B981);

  static ThemeData themeForMode(AppMode mode) {
    final seed = mode == AppMode.sos ? alertRed : primaryRed;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dailyBackground,
      colorScheme: ColorScheme.dark(
        primary: seed,
        secondary: pulseNavy,
        surface: cardBackground,
        onSurface: Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
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
        backgroundColor: cardBackground,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
