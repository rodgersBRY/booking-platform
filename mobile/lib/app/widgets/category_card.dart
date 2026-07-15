import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Icon per service category key. Falls back to a generic sparkle for
/// categories added later without a mapping.
IconData categoryIcon(String key) {
  return switch (key) {
    'haircuts' || 'hair' => Icons.content_cut,
    'beards' => Icons.face_retouching_natural,
    'hair_dyes' || 'coloring' => Icons.palette_outlined,
    'braiding' || 'styling' => Icons.gesture,
    'nails' => Icons.back_hand_outlined,
    'facials' || 'skincare' => Icons.spa_outlined,
    'massage' || 'body_treatments' => Icons.self_improvement,
    'waxing' => Icons.waves_outlined,
    'makeup' => Icons.brush_outlined,
    _ => Icons.auto_awesome,
  };
}

/// Large tappable category tile for the wizard's first step and the Home
/// screen's quick categories.
class CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.brass.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: AppColors.brass, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(label, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
