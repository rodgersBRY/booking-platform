import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/staff_appointment_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'status_chip.dart';

/// One row in the Dashboard's "Remaining Schedule" timeline: time, a
/// rail dot/connector, customer, services, and status. Reuses StatusChip
/// for the status color/label so the vocabulary matches the rest of the
/// app (booked/arrived/in_chair/late/completed) instead of a second one.
class AppointmentTimelineCard extends StatelessWidget {
  final StaffAppointmentModel appointment;

  /// Hides the connector line below the dot for the final row.
  final bool isLast;

  const AppointmentTimelineCard({
    super.key,
    required this.appointment,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(appointment.scheduledStart).toLocal();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                DateFormat('h:mm a').format(start),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.brass,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.brass.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.clientName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment.servicesLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusChip(status: appointment.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
