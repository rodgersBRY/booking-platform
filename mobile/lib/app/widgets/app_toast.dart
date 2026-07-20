import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Floating success/error feedback — replaces bare inline text under a
/// form. Built on GetX's snackbar (already a dependency, no context
/// needed) so controllers can call it directly, the same way they already
/// call `Get.offAllNamed` for navigation.
abstract class AppToast {
  static void success(String message) => _show(
    message: message,
    icon: Icons.check_circle_outline,
    foreground: AppColors.free,
    background: AppColors.freeBg,
  );

  static void error(String message) => _show(
    message: message,
    icon: Icons.error_outline,
    foreground: AppColors.late,
    background: AppColors.lateBg,
  );

  static void _show({
    required String message,
    required IconData icon,
    required Color foreground,
    required Color background,
  }) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.rawSnackbar(
      messageText: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: background,
      borderRadius: AppSpacing.radiusSm,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
