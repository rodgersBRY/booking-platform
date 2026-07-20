import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The customer booking wizard's steps, in order. Kept here so every
/// wizard page names its position the same way. The barber create-booking
/// wizard (mobile/lib/app/modules/barber/create_booking/) defines its own
/// analogous BarberBookingStep enum rather than reusing this one — the two
/// flows don't share step semantics (no "professional" step, for one) —
/// but both pass through the same [BookingProgressIndicator] below via its
/// enum-agnostic currentStep/totalSteps ints.
enum BookingStep { category, service, professional, time, review }

/// Segmented progress bar shown under a wizard AppBar — filled segments
/// for completed/current steps, muted for upcoming ones. Deliberately
/// generic (int step/total rather than a specific step enum) so any fixed-
/// length wizard in the app can reuse it.
class BookingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const BookingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          for (var i = 0; i < totalSteps; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color:
                      i <= currentStep
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
