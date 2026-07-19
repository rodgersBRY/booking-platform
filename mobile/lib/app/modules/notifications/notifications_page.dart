import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'models/notification_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import 'notifications_controller.dart';

IconData _typeIcon(String type) {
  return switch (type) {
    'booking_confirmed' => Icons.event_available,
    'booking_cancelled' => Icons.event_busy,
    'booking_completed' => Icons.check_circle_outline,
    'appointment_reminder' => Icons.notifications_active_outlined,
    'promotion' => Icons.local_offer_outlined,
    'new_service' => Icons.auto_awesome_outlined,
    'loyalty_reward' => Icons.card_giftcard_outlined,
    _ => Icons.notifications_outlined,
  };
}

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(() {
            if (controller.unreadCount.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: controller.markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonList(count: 6, itemHeight: 76);
        }
        if (!controller.signedIn.value) {
          return EmptyState(
            icon: Icons.notifications_outlined,
            title: 'Sign in to see notifications',
            subtitle: "We'll let you know about your bookings here.",
            actionLabel: 'Sign in',
            onAction: () => Get.toNamed(AppRoutes.login),
          );
        }
        if (controller.error.value != null) {
          return EmptyState(
            icon: Icons.cloud_off,
            title: "Couldn't load",
            subtitle: controller.error.value!,
            actionLabel: 'Retry',
            onAction: controller.load,
          );
        }
        if (controller.notifications.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none,
            title: 'All quiet',
            subtitle: "You'll see updates about your bookings here.",
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + 4),
            itemBuilder: (context, i) {
              final notification = controller.notifications[i];
              return _NotificationTile(
                notification: notification,
                onTap: () => controller.markRead(notification),
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.read;
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
              child: Icon(_typeIcon(notification.type), color: AppColors.brass, size: 20),
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
                    _relativeTime(notification.createdAt),
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

String _relativeTime(String iso) {
  final date = DateTime.parse(iso).toLocal();
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(date);
}
