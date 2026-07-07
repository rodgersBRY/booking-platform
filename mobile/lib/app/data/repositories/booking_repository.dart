import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../models/barber_model.dart';
import '../models/booking_submit_result.dart';
import '../models/service_model.dart';
import '../models/slot_model.dart';

/// Hits the same /api/public/* endpoints the web guest booking flow uses —
/// no auth required, no separate backend.
class BookingRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  Future<List<ServiceModel>> fetchServices() async {
    final res = await _dio.get('/public/services');
    final list = res.data['services'] as List;
    return list
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BarberModel>> fetchBarbers() async {
    final res = await _dio.get('/public/barbers');
    final list = res.data['barbers'] as List;
    return list
        .map((e) => BarberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SlotModel>> fetchAvailability({
    required String barberId,
    required String serviceId,
    required String date,
  }) async {
    final res = await _dio.get(
      '/public/availability',
      queryParameters: {'barber': barberId, 'service': serviceId, 'date': date},
    );
    final list = res.data['slots'] as List;
    return list
        .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingSubmitResult> createBooking({
    required String name,
    required String phone,
    required String barberId,
    required String serviceId,
    required String scheduledStart,
  }) async {
    try {
      final res = await _dio.post(
        '/public/bookings',
        data: {
          'client': {'name': name, 'phone': phone},
          'barberId': barberId,
          'serviceId': serviceId,
          'scheduledStart': scheduledStart,
        },
      );
      return BookingSubmitResult.success(res.data['booking'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 && data is Map && data['error'] == 'slot_taken') {
        final slots = (data['slots'] as List)
            .map((s) => SlotModel.fromJson(s as Map<String, dynamic>))
            .toList();
        return BookingSubmitResult.slotTaken(data['message'] as String?, slots);
      }
      final message = data is Map ? data['error'] as String? : null;
      return BookingSubmitResult.failure(
        'request_failed',
        message ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
