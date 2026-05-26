import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Syne';

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: _fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accent2,
        surface: AppColors.surface,
        error: AppColors.warn,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.ink,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 42, color: AppColors.ink),
        headlineSmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.ink),
        titleLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.ink),
        titleMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.ink),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.ink),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent2, width: 2),
        ),
      ),
    );
  }
}
