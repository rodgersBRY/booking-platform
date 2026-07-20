import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../models/staff_notification_model.dart';
import '../models/staff_notifications_result.dart';

/// The barber "Notifications" tab's data access — GET
/// /v1/staff/notifications and POST /v1/staff/notifications/read. Kept as
/// its own repository rather than folded into an existing one: it's a
/// distinct endpoint family (staff_notifications, per Slice 6 of
/// docs/superpowers/specs/2026-07-18-barber-workspace-design.md) that
/// none of StaffDayRepository/StaffScheduleRepository/
/// StaffCustomersRepository/StaffBookingRepository already own — mirrors
/// how "My Customers" got its own StaffCustomersRepository rather than
/// stretching an existing one. Same DioException-to-result mapping as the
/// rest of the barber module, so BarberNotificationsController never sees
/// a raw Dio error.
class StaffNotificationsRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  ({String? code, String? message}) _errorFrom(DioException e) {
    final data = e.response?.data;
    return (
      code: data is Map ? data['error'] as String? : null,
      message: data is Map ? data['message'] as String? : null,
    );
  }

  Future<StaffNotificationsResult> fetchNotifications() async {
    try {
      final res = await _dio.get('/v1/staff/notifications');
      final data = res.data as Map<String, dynamic>;
      final notifications = (data['notifications'] as List)
          .map(
            (e) => StaffNotificationModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return StaffNotificationsResult.success(
        notifications,
        data['unreadCount'] as int,
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return StaffNotificationsResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<StaffNotificationActionResult> markRead(String id) =>
      _postRead(id: id);

  Future<StaffNotificationActionResult> markAllRead() => _postRead(all: true);

  Future<StaffNotificationActionResult> _postRead({String? id, bool? all}) async {
    try {
      await _dio.post(
        '/v1/staff/notifications/read',
        data: {if (id != null) 'id': id, if (all != null) 'all': all},
      );
      return StaffNotificationActionResult.success();
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return StaffNotificationActionResult.failure(
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
