import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'barber_appointment_detail_page.dart';
import 'barber_schedule_controller.dart';
import 'models/staff_appointment_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_chip.dart';

/// The barber workspace's Schedule tab — a tabbed working calendar
/// (Today / Tomorrow / Week) per BARBER-APP.md's Schedule section.
/// Replaces the ComingSoonPage placeholder from Slices 1-2.
class BarberSchedulePage extends GetView<BarberScheduleController> {
  const BarberSchedulePage({super.key});

  static const _labels = {
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'week': 'Week',
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: scheduleRanges.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule'),
          bottom: TabBar(
            onTap: (i) => controller.changeRange(scheduleRanges[i]),
            tabs: [for (final r in scheduleRanges) Tab(text: _labels[r])],
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshSchedule,
            child: Obx(() {
              if (controller.loading.value && controller.schedule.isEmpty) {
                return const SkeletonList(count: 5, itemHeight: 84);
              }

              if (controller.schedule.isEmpty) {
                final error = controller.loadError.value;
                if (error != null) {
                  return ListView(
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      EmptyState(
                        icon: Icons.cloud_off,
                        title: "Couldn't load your schedule",
                        subtitle: error,
                        actionLabel: 'Retry',
                        onAction: controller.load,
                      ),
                    ],
                  );
                }
                return ListView(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    EmptyState(
                      icon: Icons.event_available_outlined,
                      title: _emptyTitle(controller.range.value),
                      subtitle: _emptySubtitle(controller.range.value),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (controller.refreshError.value != null) ...[
                    _RefreshErrorBanner(
                      message: controller.refreshError.value!,
                      onRetry: controller.refreshSchedule,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  for (final appointment in controller.schedule)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                      child: _ScheduleAppointmentCard(
                        appointment: appointment,
                        onTap:
                            () => Get.to(
                              () => BarberAppointmentDetailPage(
                                bookingId: appointment.bookingId,
                              ),
                            ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
        floatingActionButton: const _NewBookingFab(),
      ),
    );
  }

  String _emptyTitle(String range) => switch (range) {
    'today' => 'No appointments today.',
    'tomorrow' => 'No appointments tomorrow.',
    _ => 'No appointments this week.',
  };

  String _emptySubtitle(String range) => switch (range) {
    'today' => 'Enjoy your free time.',
    'tomorrow' => 'Nothing on the books yet.',
    _ => 'Nothing on the books for this week yet.',
  };
}

/// Bottom-right "+ New Booking" FAB per BARBER-APP.md's Floating Action
/// Button section. Booking creation is Slice 4 — until that lands, this
/// stays a disabled/tooltip stub matching the exact pattern
/// NextAppointmentCard uses for its not-yet-wired buttons, rather than a
/// button that silently does nothing.
class _NewBookingFab extends StatelessWidget {
  const _NewBookingFab();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Creating bookings is coming in a future update',
      child: FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Theme.of(context).disabledColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
      ),
    );
  }
}

class _ScheduleAppointmentCard extends StatelessWidget {
  final StaffAppointmentModel appointment;
  final VoidCallback onTap;

  const _ScheduleAppointmentCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(appointment.scheduledStart).toLocal();

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(start),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment.durationMinutes} min',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.clientName, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(appointment.servicesLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(status: appointment.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RefreshErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.lateBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.late, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.late, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
