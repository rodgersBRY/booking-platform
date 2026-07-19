import 'package:flutter/material.dart';

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
