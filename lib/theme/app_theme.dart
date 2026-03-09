import 'package:flutter/material.dart';

// Centralized theme and color tokens for the app.
// Start with a greyscale palette and named tokens for later customization.

class AppColors {
  // Brand primary color
  static const Color crayolaBlue = Color(0xFF4F7BD9);
  
  // Text and contrast
  static const Color charcoalBlue = Color(0xFF2F3A45);
  static const Color coolSteel = Color(0xFF9AA6B2);
  
  // Surface and background
  static const Color platinum = Color(0xFFF4F6F8);
  static const Color white = Color(0xFFFFFFFF);
  
  // Secondary accent
  static const Color tropicalTeal = Color(0xFF3AAFA9);
  static const Color lavender = Color(0xFFDCE6FA);
  
  // Semantic feedback colors
  static const Color errorRed = Color(0xFFE35D5D); // Lobster Pink
  static const Color successGreen = Color(0xFF4CAF7D); // Mint Leaf
  static const Color warningYellow = Color(0xFFF2C94C); // Tuscan Sun

  // Greyscale mapping (maintained for backward compatibility)
  static const Color black = Color(0xFF000000);
  static const Color grey900 = charcoalBlue;
  static const Color grey800 = Color(0xFF3A4A5F);
  static const Color grey700 = coolSteel;
  static const Color grey600 = Color(0xFFB0B8C6);
  static const Color grey500 = Color(0xFFC5CDD5);
  static const Color grey400 = lavender;
  static const Color grey300 = Color(0xFFE8ECF2);
  static const Color grey200 = Color(0xFFF0F3F7);
  static const Color grey100 = platinum;

  // Semantic slots
  static const Color accent = crayolaBlue;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.crayolaBlue,
        brightness: Brightness.light,
        primary: AppColors.crayolaBlue,
        onPrimary: AppColors.white,
        secondary: AppColors.tropicalTeal,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.charcoalBlue,
      ),
      scaffoldBackgroundColor: AppColors.platinum,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.platinum,
        foregroundColor: AppColors.charcoalBlue,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoalBlue,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.crayolaBlue,
          foregroundColor: AppColors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.charcoalBlue,
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
