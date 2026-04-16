import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  // Cấu hình Light Theme
  static ThemeData get lightTheme {
    final baseScheme = ColorScheme.light(
      primary: AppColors.primaryGreen,
      secondary: AppColors.earthyBrown,
      surface: AppColors.surfaceLight,
      background: AppColors.backgroundLight,
      error: AppColors.error,
      onPrimary: AppColors.textOnPrimary,
      onSecondary: AppColors.textOnPrimary,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
      outline: AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryGreen,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      dividerColor: AppColors.borderLight,
      iconTheme: const IconThemeData(color: AppColors.primaryGreen),

      // Cấu hình AppBar xanh lá thanh lịch
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Cấu hình Nút bấm bo tròn năng động
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDarkGreen,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      // Cấu hình Thẻ nhiệm vụ (TaskCard)
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 2,
        shadowColor: AppColors.primaryGreen.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMutedLight,
        disabledColor: AppColors.surfaceMutedLight,
        selectedColor: AppColors.primaryGreen.withValues(alpha: 0.14),
        secondarySelectedColor: AppColors.primaryGreen.withValues(alpha: 0.14),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primaryDarkGreen,
        contentTextStyle: TextStyle(color: AppColors.textOnPrimary),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.12),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: AppColors.primaryGreen),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
      ),
    );
  }

  // Cấu hình Dark Theme
  static ThemeData get darkTheme {
    final baseScheme = ColorScheme.dark(
      primary: AppColors.primaryGreen,
      secondary: AppColors.earthyBrown,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
      error: AppColors.error,
      onPrimary: AppColors.textOnPrimary,
      onSecondary: AppColors.textOnPrimary,
      onSurface: AppColors.textOnDark,
      onBackground: AppColors.textOnDark,
      outline: AppColors.borderDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryGreen,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      dividerColor: AppColors.borderDark,
      iconTheme: const IconThemeData(color: AppColors.primaryGreen),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMutedDark,
        disabledColor: AppColors.surfaceMutedDark,
        selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
        secondarySelectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
        labelStyle: const TextStyle(color: AppColors.textOnDark),
        secondaryLabelStyle: const TextStyle(color: AppColors.textOnDark),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceMutedDark,
        contentTextStyle: TextStyle(color: AppColors.textOnDark),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.14),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: AppColors.primaryGreen),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
      ),
    );
  }
}