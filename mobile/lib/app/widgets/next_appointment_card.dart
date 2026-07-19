import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modules/barber/models/staff_appointment_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'booking_source_badge.dart';

/// The largest card on the barber Dashboard — BARBER-APP.md calls this
/// out explicitly. Customer, time, services, duration, and booking
/// source.
///
/// "View Details" and "Start Service" are no-ops in this slice: the
/// appointment-detail screen and the start/complete-service actions are
/// Slice 3 work (docs/superpowers/specs/2026-07-18-barber-workspace-design.md).
/// Rather than wire either button to nothing — a tap with no visible
/// effect reads as broken, not "coming soon" — both stay disabled with an
/// explanatory tooltip until a Slice 3 caller passes real callbacks in.
class NextAppointmentCard extends StatelessWidget {
  final StaffAppointmentModel appointment;
  final VoidCallback? onViewDetails;
  final VoidCallback? onStartService;

  const NextAppointmentCard({
    super.key,
    required this.appointment,
    this.onViewDetails,
    this.onStartService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(appointment.scheduledStart).toLocal();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.brass.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEXT APPOINTMENT',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.brass,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              BookingSourceBadge(channel: appointment.channel),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(appointment.clientName, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.brass),
              const SizedBox(width: 4),
              Text(DateFormat('h:mm a').format(start), style: theme.textTheme.titleMedium),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.timelapse, size: 16, color: AppColors.brass),
              const SizedBox(width: 4),
              Text(
                '${appointment.durationMinutes} min',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(appointment.servicesLabel, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message:
                      onViewDetails == null
                          ? 'Appointment details are coming in a future update'
                          : 'View Details',
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    child: const Text('View Details'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Tooltip(
                  message:
                      onStartService == null
                          ? 'Starting a service is coming in a future update'
                          : 'Start Service',
                  child: ElevatedButton(
                    onPressed: onStartService,
                    child: const Text('Start Service'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
