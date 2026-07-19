import 'staff_notification_model.dart';

/// Result of GET /v1/staff/notifications — same named-constructor pattern
/// as StaffCustomersResult, so StaffNotificationsRepository never lets a
/// raw DioException reach BarberNotificationsController.
class StaffNotificationsResult {
  final bool success;
  final List<StaffNotificationModel>? notifications;
  final int? unreadCount;
  final String? errorCode;
  final String? message;

  StaffNotificationsResult.success(this.notifications, this.unreadCount)
    : success = true,
      errorCode = null,
      message = null;

  StaffNotificationsResult.failure(this.errorCode, this.message)
    : success = false,
      notifications = null,
      unreadCount = null;
}

/// Result of POST /v1/staff/notifications/read (single id or `all: true`).
/// Deliberately just a success flag + message — the caller already knows
/// which notification(s) it optimistically marked read locally and only
/// needs to know whether to keep or revert that change.
class StaffNotificationActionResult {
  final bool success;
  final String? message;

  StaffNotificationActionResult.success() : success = true, message = null;

  StaffNotificationActionResult.failure(this.message) : success = false;
}
