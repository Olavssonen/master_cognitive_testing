import 'package:flutter/material.dart';

// Centralized theme and color tokens for the app.
// Start with a greyscale palette and named tokens for later customization.

class AppColors {
  // Greyscale base
  static const Color black = Color(0xFF000000);
  static const Color grey900 = Color(0xFF212121);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // Accent slot (placeholder) — change to a color when you decide on an accent
  static const Color accent = grey700;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.grey900,
        onPrimary: AppColors.white,
        secondary: AppColors.grey700,
        onSecondary: AppColors.white,
        background: AppColors.grey100,
        surface: AppColors.white,
        onSurface: AppColors.grey900,
      ),
      scaffoldBackgroundColor: AppColors.grey100,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.grey100,
        foregroundColor: AppColors.grey900,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grey900,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.grey800,
          foregroundColor: AppColors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.grey800,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 1,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
}
