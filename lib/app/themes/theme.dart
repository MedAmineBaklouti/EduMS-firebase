import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightColorScheme,

      // App Bar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: AppColors.lightColorScheme.primary,
        foregroundColor: AppColors.lightColorScheme.onPrimary,
        surfaceTintColor: AppColors.lightColorScheme.primary,
        iconTheme: IconThemeData(
          color: AppColors.lightColorScheme.onPrimary,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.lightColorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: AppColors.lightColorScheme.onPrimary.withOpacity(0.9),
          fontSize: 14,
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightColorScheme.primary,
          foregroundColor: AppColors.lightColorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightColorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightColorScheme.surfaceVariant.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.lightColorScheme.surfaceVariant,
      ),

      // Dialogs
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.darkColorScheme,

      // Dark mode specific overrides
      cardTheme: CardTheme(
        color: AppColors.darkColorScheme.surfaceVariant,
      ),

      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.darkColorScheme.surfaceVariant.withOpacity(0.2),
      ),
    ).copyWith(
      // Inherit all other properties from light theme
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: AppColors.darkColorScheme.primary,
        foregroundColor: AppColors.darkColorScheme.onPrimary,
        surfaceTintColor: AppColors.darkColorScheme.primary,
        iconTheme: IconThemeData(
          color: AppColors.darkColorScheme.onPrimary,
        ),
        titleTextStyle: lightTheme.appBarTheme.titleTextStyle?.copyWith(
          color: AppColors.darkColorScheme.onPrimary,
        ),
        toolbarTextStyle: lightTheme.appBarTheme.toolbarTextStyle?.copyWith(
          color: AppColors.darkColorScheme.onPrimary.withOpacity(0.9),
        ),
      ),
      elevatedButtonTheme: lightTheme.elevatedButtonTheme,
      textButtonTheme: lightTheme.textButtonTheme,
      dialogTheme: lightTheme.dialogTheme,
    );
  }
}