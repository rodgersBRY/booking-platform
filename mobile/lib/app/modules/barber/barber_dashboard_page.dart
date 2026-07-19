import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'models/staff_presence.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/appointment_timeline_card.dart';
import '../../widgets/availability_card.dart';
import '../../widgets/daily_summary_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/next_appointment_card.dart';
import '../../widgets/skeleton_loader.dart';
import 'barber_dashboard_controller.dart';

/// The barber workspace's Dashboard tab — "managing today's work" per
/// docs/superpowers/specs/2026-07-18-barber-workspace-design.md. Mirrors
/// HomePage's loading/error/RefreshIndicator structure with barber data
/// (presence, today's summary, next appointment, remaining schedule)
/// in place of the customer booking shortcuts.
class BarberDashboardPage extends GetView<BarberDashboardController> {
  const BarberDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshDay,
          child: Obx(() {
            if (controller.loading.value && controller.day.value == null) {
              return const _DashboardSkeleton();
            }

            final day = controller.day.value;
            if (day == null) {
              return ListView(
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  EmptyState(
                    icon: Icons.cloud_off,
                    title: "Couldn't load your day",
                    subtitle:
                        controller.loadError.value ??
                        'Check your connection and try again.',
                    actionLabel: 'Retry',
                    onAction: controller.load,
                  ),
                ],
              );
            }

            final hasAppointments = day.summary.total > 0;
            final remaining = day.remainingSchedule;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _Header(controller: controller),
                const SizedBox(height: AppSpacing.lg),
                if (controller.refreshError.value != null) ...[
                  _RefreshErrorBanner(
                    message: controller.refreshError.value!,
                    onRetry: controller.refreshDay,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AvailabilityCard(
                  presence: day.presence,
                  presenceUpdatedAt: day.presenceUpdatedAt,
                  busy: controller.presenceUpdating.value,
                  onChangeStatus: () => _changeStatus(context, day.presence),
                ),
                const SizedBox(height: AppSpacing.md),
                DailySummaryCard(
                  summary: day.summary,
                  workingHoursLabel: day.workingHours?.formattedRange,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!hasAppointments)
                  const EmptyState(
                    icon: Icons.free_breakfast_outlined,
                    title: 'No appointments today.',
                    subtitle: 'Enjoy your free time.',
                  )
                else ...[
                  if (day.nextAppointment != null) ...[
                    Text(
                      'Next Appointment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    NextAppointmentCard(appointment: day.nextAppointment!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (remaining.isNotEmpty) ...[
                    Text(
                      'Remaining Schedule',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < remaining.length; i++)
                      AppointmentTimelineCard(
                        appointment: remaining[i],
                        isLast: i == remaining.length - 1,
                      ),
                  ],
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, StaffPresence current) async {
    final selected = await showChangeStatusSheet(context, current);
    if (selected == null) return;

    await controller.changePresence(selected);

    final error = controller.presenceError.value;
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _Header extends StatelessWidget {
  final BarberDashboardController controller;

  const _Header({required this.controller});

  static const _roleLabels = {
    'barber': 'Barber',
    'beautician': 'Beautician',
    'masseuse': 'Masseuse',
  };

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final staff = controller.staff.value;
      const radius = 28.0;
      final fallback = CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.navy,
        child: Text(
          _initials(staff?.name ?? ''),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      );
      final avatarUrl = staff?.avatarUrl;

      return Row(
        children: [
          avatarUrl == null || avatarUrl.isEmpty
              ? fallback
              : CachedNetworkImage(
                imageUrl: avatarUrl,
                imageBuilder:
                    (context, image) =>
                        CircleAvatar(radius: radius, backgroundImage: image),
                placeholder: (context, _) => fallback,
                errorWidget: (context, _, __) => fallback,
              ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(controller.greeting, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(staff?.name ?? 'Welcome', style: theme.textTheme.displaySmall),
                if (staff != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _roleLabels[staff.role] ?? staff.role,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
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

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 64, width: 240),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 88),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 120),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 200),
      ],
    );
  }
}
