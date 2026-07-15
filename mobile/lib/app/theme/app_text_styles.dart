import 'package:flutter/material.dart';

/// Size/weight scale beyond AppTheme's three base overrides
/// (headlineSmall/titleLarge/bodyMedium). Deliberately colorless — AppTheme
/// applies the brightness-appropriate color when building light/dark
/// ThemeData, so these stay reusable across both.
abstract class AppTextStyles {
  static const displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const bodySmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
}
