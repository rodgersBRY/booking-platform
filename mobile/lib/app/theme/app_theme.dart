import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  static ThemeData get light => _build(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
          primary: AppColors.navy,
          secondary: AppColors.brass,
          surface: AppColors.card,
        ),
        background: AppColors.canvas,
        cardColor: AppColors.card,
        borderColor: const Color(0xFFE5E7EB),
        textColor: AppColors.navy,
        mutedTextColor: Colors.black54,
      );

  static ThemeData get dark => _build(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brassLight,
          brightness: Brightness.dark,
          primary: AppColors.brassLight,
          secondary: AppColors.brass,
          surface: AppColors.cardDark,
        ),
        background: AppColors.canvasDark,
        cardColor: AppColors.cardDark,
        borderColor: AppColors.borderDark,
        textColor: Colors.white,
        mutedTextColor: Colors.white70,
      );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color background,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      // TabBar always lives inside the (always-navy) AppBar, so its label
      // colors are fixed too — not colorScheme.primary, which is navy in
      // light mode and would render invisible against the navy bar.
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.brassLight,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brass,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brass, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        bodyMedium: TextStyle(color: textColor),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: textColor),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: textColor),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: textColor),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: mutedTextColor),
      ),
    );
  }
}
