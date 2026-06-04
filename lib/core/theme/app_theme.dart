import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color.fromARGB(255, 0, 0, 0);
  static const Color surface = Color.fromARGB(255, 0, 0, 0);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFDDDDDD);
  static const Color onSurfaceVariant = Color(0xFFADADAD);
  static const Color onSurfaceVariantDark = Color(0xFF636363);
  static const Color backgroundVariant = Color(0xFF212121);
  static const Color backgroundVariantDark = Color(0xFF151515);
  static const Color backgroundVariantLight = Color(0xFF2D2D2D);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Sora',
      primaryColor: AppColors.onSurface,
      scaffoldBackgroundColor: AppColors.background,

      /// REMOVE MATERIAL RIPPLE EFFECTS
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      scrollbarTheme: const ScrollbarThemeData(
        radius: Radius.circular(4),
        thickness: WidgetStatePropertyAll(4),
        thumbColor: WidgetStatePropertyAll(AppColors.onSurfaceVariantDark),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: AppColors.onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
        headlineSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        labelLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
