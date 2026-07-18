import 'package:get/get.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/notifications_repository.dart';

class NotificationsController extends GetxController {
  final NotificationsRepository _repo = NotificationsRepository();
  final AuthRepository _authRepo = AuthRepository();

  final loading = true.obs;
  final signedIn = false.obs;
  final error = RxnString();

  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;

    final client = await _authRepo.fetchMe();
    signedIn.value = client != null;
    if (client == null) {
      loading.value = false;
      return;
    }

    try {
      final result = await _repo.fetchNotifications();
      notifications.value = result.notifications;
      unreadCount.value = result.unreadCount;
    } catch (_) {
      error.value = "Couldn't load notifications. Please try again.";
    } finally {
      loading.value = false;
    }
  }

  Future<void> markRead(NotificationModel notification) async {
    if (notification.read) return;
    // Optimistic — the list doesn't need to round-trip to reflect this.
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = NotificationModel(
        id: notification.id,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        bookingId: notification.bookingId,
        read: true,
        createdAt: notification.createdAt,
      );
      unreadCount.value = (unreadCount.value - 1).clamp(0, 1 << 30);
    }
    try {
      await _repo.markRead(notification.id);
    } catch (_) {
      // Non-critical — worst case it shows read locally until next load().
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;
    notifications.value = notifications
        .map(
          (n) => NotificationModel(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            bookingId: n.bookingId,
            read: true,
            createdAt: n.createdAt,
          ),
        )
        .toList();
    unreadCount.value = 0;
    try {
      await _repo.markAllRead();
    } catch (_) {
      // Non-critical — worst case it shows read locally until next load().
    }
  }
}
