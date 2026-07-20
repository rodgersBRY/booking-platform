import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../models/booking_action_result.dart';
import '../models/booking_model.dart';
import '../../booking/models/slot_model.dart';

/// The signed-in client's own bookings — /api/v1/account/bookings* on the
/// same backend. Distinct from booking_repository.dart, which stays scoped
/// to creating a new booking through the guest/account wizard.
class BookingsRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  Future<Map<String, List<BookingModel>>> fetchMyBookings() async {
    final res = await _dio.get('/v1/account/bookings');
    
    List<BookingModel> bucket(String key) {
      final list = res.data[key] as List;
      return list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return {
      'upcoming': bucket('upcoming'),
      'completed': bucket('completed'),
      'cancelled': bucket('cancelled'),
    };
  }

  Future<BookingActionResult> cancelBooking(String id) async {
    try {
      await _dio.post('/v1/account/bookings/$id/cancel');
      return BookingActionResult.success();
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = data is Map ? data['error'] as String? : null;
      final message = data is Map ? data['message'] as String? : null;
      return BookingActionResult.failure(
        code,
        message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<BookingActionResult> rescheduleBooking({
    required String id,
    required String scheduledStart,
    String? staffId,
  }) async {
    try {
      final res = await _dio.post(
        '/v1/account/bookings/$id/reschedule',
        data: {
          'scheduledStart': scheduledStart,
          if (staffId != null) 'staffId': staffId,
        },
      );
      final booking = BookingModel.fromJson(
        res.data['booking'] as Map<String, dynamic>,
      );
      return BookingActionResult.success(booking);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 &&
          data is Map &&
          data['error'] == 'slot_taken') {
        final slots = (data['slots'] as List)
            .map((s) => SlotModel.fromJson(s as Map<String, dynamic>))
            .toList();
        return BookingActionResult.slotTaken(data['message'] as String?, slots);
      }
      final code = data is Map ? data['error'] as String? : null;
      final message = data is Map ? data['message'] as String? : null;
      return BookingActionResult.failure(
        code,
        message ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
