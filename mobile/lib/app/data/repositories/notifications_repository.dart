import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  Future<({List<NotificationModel> notifications, int unreadCount})> fetchNotifications() async {
    final res = await _dio.get('/v1/account/notifications');
    final list = res.data['notifications'] as List;
    return (
      notifications: list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: res.data['unreadCount'] as int,
    );
  }

  Future<void> markRead(String id) async {
    await _dio.post('/v1/account/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.post('/v1/account/notifications/read-all');
  }
}
