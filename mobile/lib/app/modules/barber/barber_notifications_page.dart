import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import 'barber_appointment_detail_page.dart';
import 'barber_notifications_controller.dart';
import 'models/staff_notification_model.dart';

/// Icon for a staff_notifications row type — the four booking-lifecycle
/// events Slice 6's server-side writers emit (see
/// docs/superpowers/specs/2026-07-18-barber-workspace-design.md Slice 6).
/// Distinct from the customer module's `_typeIcon`
/// (lib/app/modules/notifications/notifications_page.dart), which covers a
/// different type vocabulary (promotions, loyalty, reminders, ...).
IconData _typeIcon(String type) {
  return switch (type) {
    'booking_created' => Icons.event_available,
    'booking_cancelled' => Icons.event_busy,
    'booking_rescheduled' => Icons.update,
    'customer_checked_in' => Icons.how_to_reg,
    _ => Icons.notifications_outlined,
  };
}

/// The barber workspace's Notifications tab — timeline of booking-lifecycle
/// events (created/cancelled/rescheduled/checked-in) for this staff
/// member's bookings, per BARBER-APP.md's Notifications section and Slice 6
/// of docs/superpowers/specs/2026-07-18-barber-workspace-design.md.
/// Replaces the ComingSoonPage placeholder from Slices 1-5.
class BarberNotificationsPage extends GetView<BarberNotificationsController> {
  const BarberNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(() {
            if (controller.unreadCount.value == 0) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: controller.markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonList(count: 6, itemHeight: 76);
        }

        if (controller.notifications.isEmpty) {
          final error = controller.loadError.value;
          if (error != null) {
            return ListView(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                EmptyState(
                  icon: Icons.cloud_off,
                  title: "Couldn't load notifications",
                  subtitle: error,
                  actionLabel: 'Retry',
                  onAction: controller.load,
                ),
              ],
            );
          }
          return const EmptyState(
            icon: Icons.notifications_outlined,
            title: 'All caught up',
            subtitle: "You're all caught up.",
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (controller.refreshError.value != null) ...[
                _RefreshErrorBanner(
                  message: controller.refreshError.value!,
                  onRetry: controller.refreshNotifications,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              for (final notification in controller.notifications)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                  child: _NotificationTile(
                    notification: notification,
                    onTap: () {
                      controller.markRead(notification);
                      // Same Get.to(bookingId: ...) navigation the
                      // Dashboard's next-appointment card and Schedule's
                      // rows use — a notification about a booking should
                      // take the barber straight to that booking's detail
                      // screen, same as tapping the booking anywhere else.
                      final bookingId = notification.bookingId;
                      if (bookingId != null) {
                        Get.to(
                          () => BarberAppointmentDetailPage(
                            bookingId: bookingId,
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final StaffNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = notification.isUnread;
    final created = DateTime.tryParse(notification.createdAt)?.toLocal();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: unread
              ? AppColors.brass.withValues(alpha: 0.08)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: unread ? Border.all(color: AppColors.brassLight) : null,
          boxShadow: unread
              ? null
              : [
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.brass.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                _typeIcon(notification.type),
                color: AppColors.brass,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    created != null ? relativeTimeLabel(created) : '',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.brass,
                  shape: BoxShape.circle,
                ),
              ),
          ],
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
