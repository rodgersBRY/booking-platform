import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The booking wizard's steps, in order. Kept here so every wizard page
/// names its position the same way.
enum BookingStep { category, service, professional, time, review }

/// Segmented progress bar shown under the wizard AppBar — filled segments
/// for completed/current steps, muted for upcoming ones.
class BookingProgressIndicator extends StatelessWidget {
  final BookingStep current;

  const BookingProgressIndicator({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final active = current.index;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          for (var i = 0; i < BookingStep.values.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color:
                      i <= active
                          ? AppColors.brass
                          : AppColors.brass.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
