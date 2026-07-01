import 'package:flutter/material.dart';

import '../enums/app_mode.dart';

class PulseLinkTheme {
  const PulseLinkTheme._();

  static const primaryRed = Color(0xFFE31837);
  static const alertRed = Color(0xFFFF334B);
  static const deepBloodRed = Color(0xFF8A0012);
  static const dailyBackground = Color(0xFF101113);
  static const cardBackground = Color(0xFF191B1F);
  static const mutedText = Color(0xFF9DA3AF);
  static const successGreen = Color(0xFF10B981);

  static ThemeData themeForMode(AppMode mode) {
    final seed = mode == AppMode.sos ? alertRed : primaryRed;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dailyBackground,
      colorScheme: ColorScheme.dark(
        primary: seed,
        secondary: deepBloodRed,
        surface: cardBackground,
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
