import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../models/presence_update_result.dart';
import '../models/staff_day_model.dart';
import '../models/staff_day_result.dart';
import '../models/staff_presence.dart';

/// The signed-in barber's "today" view — /api/v1/staff/day and
/// /api/v1/staff/presence. Mirrors bookings_repository.dart's
/// DioException-to-result mapping so BarberDashboardController never sees
/// a raw Dio error.
class StaffDayRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  Future<StaffDayResult> fetchDay() async {
    try {
      final res = await _dio.get('/v1/staff/day');
      return StaffDayResult.success(
        StaffDayModel.fromJson(res.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map ? data['error'] as String? : null;
      final message = data is Map ? data['message'] as String? : null;
      return StaffDayResult.failure(
        code,
        message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<PresenceUpdateResult> updatePresence(StaffPresence presence) async {
    try {
      final res = await _dio.patch(
        '/v1/staff/presence',
        data: {'presence': presence.value},
      );
      return PresenceUpdateResult.success(
        StaffPresence.fromJson(res.data['presence'] as String),
        res.data['presenceUpdatedAt'] as String?,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map ? data['error'] as String? : null;
      final message = data is Map ? data['message'] as String? : null;
      return PresenceUpdateResult.failure(
        code,
        message ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
