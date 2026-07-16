import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../models/booking_submit_result.dart';
import '../models/service_model.dart';
import '../models/slot_model.dart';
import '../models/staff_model.dart';

/// Hits the same /api/public/* endpoints the web guest booking flow uses —
/// no auth required, no separate backend.
class BookingRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  Future<List<ServiceModel>> fetchServices() async {
    final res = await _dio.get('/v1/public/services');
    final list = res.data['services'] as List;
    return list
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The endpoint is still "/public/barbers" server-side (legacy name), but
  /// it now returns any bookable role. Pass [serviceId] to get only staff
  /// eligible for that service — omit it to get everyone.
  Future<List<StaffModel>> fetchStaff({String? serviceId}) async {
    final res = await _dio.get(
      '/v1/public/barbers',
      queryParameters: serviceId != null ? {'serviceId': serviceId} : null,
    );
    final list = res.data['barbers'] as List;
    return list
        .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SlotModel>> fetchAvailability({
    required String staffId,
    required String serviceId,
    required String date,
  }) async {
    final res = await _dio.get(
      '/v1/public/availability',
      queryParameters: {'staff': staffId, 'service': serviceId, 'date': date},
    );
    final list = res.data['slots'] as List;
    return list
        .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingSubmitResult> createBooking({
    required String name,
    required String phone,
    required String staffId,
    required String serviceId,
    required String scheduledStart,
  }) async {
    try {
      final res = await _dio.post(
        '/v1/public/bookings',
        data: {
          'client': {'name': name, 'phone': phone},
          'staffId': staffId,
          'serviceId': serviceId,
          'scheduledStart': scheduledStart,
        },
      );
      return BookingSubmitResult.success(res.data['booking'] as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleBookingError(e);
    }
  }

  /// Same as [createBooking], but for a signed-in client — creates the
  /// booking directly against their account instead of finding-or-creating
  /// a guest client by phone, so it's guaranteed to show up in their own
  /// Appointments list.
  Future<BookingSubmitResult> createBookingForAccount({
    required String staffId,
    required String serviceId,
    required String scheduledStart,
  }) async {
    try {
      final res = await _dio.post(
        '/v1/account/bookings',
        data: {
          'staffId': staffId,
          'serviceId': serviceId,
          'scheduledStart': scheduledStart,
        },
      );
      return BookingSubmitResult.success(res.data['booking'] as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleBookingError(e);
    }
  }

  BookingSubmitResult _handleBookingError(DioException e) {
    final data = e.response?.data;
    if (e.response?.statusCode == 409 && data is Map && data['error'] == 'slot_taken') {
      final slots = (data['slots'] as List)
          .map((s) => SlotModel.fromJson(s as Map<String, dynamic>))
          .toList();
      return BookingSubmitResult.slotTaken(data['message'] as String?, slots);
    }
    final message = data is Map ? data['message'] as String? : null;
    return BookingSubmitResult.failure(
      'request_failed',
      message ?? 'Something went wrong. Please try again.',
    );
  }
}
