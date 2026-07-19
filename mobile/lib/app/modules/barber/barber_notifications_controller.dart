import 'package:get/get.dart';

import 'barber_shell_controller.dart';
import 'models/staff_notification_model.dart';
import 'repositories/staff_notifications_repository.dart';

/// Drives the barber "Notifications" tab — GET /v1/staff/notifications,
/// unread highlighting, tap-to-read, and mark-all-read. Per Slice 6 of
/// docs/superpowers/specs/2026-07-18-barber-workspace-design.md and
/// BARBER-APP.md's Notifications section.
class BarberNotificationsController extends GetxController {
  final StaffNotificationsRepository _repo = StaffNotificationsRepository();

  final loading = true.obs;
  final notifications = <StaffNotificationModel>[].obs;
  final unreadCount = 0.obs;

  /// Set only when there's nothing loaded to fall back on — drives the
  /// full-page error state.
  final loadError = RxnString();

  /// Set when a refresh fails but [notifications] already has data from
  /// an earlier successful load — drives an inline retry banner instead
  /// of blanking the page.
  final refreshError = RxnString();

  Worker? _tabWorker;
  Worker? _badgeWorker;

  @override
  void onInit() {
    super.onInit();
    load();

    // Mirror the unread count onto the shell so the bottom-nav tab can
    // show a badge without the shell needing to know how notifications
    // are fetched — same "push state to a sibling controller found via
    // Get.isRegistered" idea as
    // BarberAppointmentDetailController._refreshSiblingScreens, just
    // pushed upward to the shell instead of sideways to another tab.
    _badgeWorker = ever<int>(unreadCount, (value) {
      if (Get.isRegistered<BarberShellController>()) {
        Get.find<BarberShellController>().unreadNotifications.value = value;
      }
    });

    // Refresh whenever the barber switches back to this tab — same
    // rationale as BarberCustomersController's tab-focus refresh (the
    // shell keeps every tab alive in an IndexedStack, so there's no
    // page-opened lifecycle hook to use instead).
    if (Get.isRegistered<BarberShellController>()) {
      final shell = Get.find<BarberShellController>();
      _tabWorker = ever<int>(shell.currentTab, (tab) {
        if (tab == barberNotificationsTabIndex) refreshNotifications();
      });
    }
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    _badgeWorker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    loadError.value = null;
    try {
      await _fetch();
    } finally {
      loading.value = false;
    }
  }

  /// Pull-to-refresh / tab-focus refresh. Never shows the skeleton and
  /// never clears already-loaded data on failure.
  Future<void> refreshNotifications() async {
    refreshError.value = null;
    await _fetch();
  }

  Future<void> _fetch() async {
    final result = await _repo.fetchNotifications();
    if (result.success) {
      notifications.assignAll(result.notifications ?? []);
      unreadCount.value = result.unreadCount ?? 0;
      loadError.value = null;
      refreshError.value = null;
    } else if (notifications.isEmpty) {
      loadError.value = result.message;
    } else {
      refreshError.value = result.message;
    }
  }

  /// Optimistic tap-to-read: flips the entry locally (and decrements the
  /// unread count) immediately, then confirms against the API and reverts
  /// on failure.
  Future<void> markRead(StaffNotificationModel notification) async {
    if (!notification.isUnread) return;
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index == -1) return;

    final previous = notification;
    notifications[index] = previous.markedRead(
      DateTime.now().toUtc().toIso8601String(),
    );
    unreadCount.value = (unreadCount.value - 1).clamp(0, 1 << 30);

    final result = await _repo.markRead(notification.id);
    if (!result.success) {
      final revertIndex = notifications.indexWhere(
        (n) => n.id == notification.id,
      );
      if (revertIndex != -1) notifications[revertIndex] = previous;
      unreadCount.value = (unreadCount.value + 1).clamp(0, 1 << 30);
    }
  }

  /// Optimistic mark-all-read, same revert-on-failure contract as
  /// [markRead].
  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;
    final previous = notifications.toList();
    final previousUnreadCount = unreadCount.value;
    final now = DateTime.now().toUtc().toIso8601String();

    notifications.assignAll(
      notifications.map((n) => n.isUnread ? n.markedRead(now) : n).toList(),
    );
    unreadCount.value = 0;

    final result = await _repo.markAllRead();
    if (!result.success) {
      notifications.assignAll(previous);
      unreadCount.value = previousUnreadCount;
    }
  }
}
