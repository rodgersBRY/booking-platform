import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../../booking/models/service_model.dart';
import '../../booking/models/slot_model.dart';
import '../models/client_search_result.dart';
import '../models/new_client_result.dart';
import '../models/staff_availability_result.dart';
import '../models/staff_booking_create_result.dart';
import '../models/staff_client_model.dart';
import '../models/staff_services_result.dart';

/// The barber create-booking wizard's data access — /v1/staff/clients*,
/// /v1/staff/services, /v1/staff/availability, and /v1/staff/bookings.
/// Mirrors StaffScheduleRepository/StaffDayRepository's DioException-to-
/// result mapping so BarberCreateBookingController never sees a raw Dio
/// error.
class StaffBookingRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  ({String? code, String? message}) _errorFrom(DioException e) {
    final data = e.response?.data;
    return (
      code: data is Map ? data['error'] as String? : null,
      message: data is Map ? data['message'] as String? : null,
    );
  }

  Future<ClientSearchResult> searchClients(String query) async {
    try {
      final res = await _dio.get(
        '/v1/staff/clients/search',
        queryParameters: {'q': query},
      );
      final data = res.data as Map<String, dynamic>;
      final clients = (data['clients'] as List)
          .map((e) => StaffClientModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ClientSearchResult.success(clients);
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return ClientSearchResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<NewClientResult> createClient({
    required String name,
    required String phone,
  }) async {
    try {
      final res = await _dio.post(
        '/v1/staff/clients',
        data: {'name': name, 'phone': phone},
      );
      return NewClientResult.success(
        StaffClientModel.fromJson(res.data['client'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      if (e.response?.statusCode == 409 && err.code == 'phone_taken') {
        return NewClientResult.phoneTaken(
          err.message ?? 'A client with this phone number already exists.',
        );
      }
      return NewClientResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<StaffServicesResult> fetchServices() async {
    try {
      final res = await _dio.get('/v1/staff/services');
      final services = (res.data['services'] as List)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return StaffServicesResult.success(services);
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return StaffServicesResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<StaffAvailabilityResult> fetchAvailability({
    required String date,
    required String serviceId,
  }) async {
    try {
      final res = await _dio.get(
        '/v1/staff/availability',
        queryParameters: {'date': date, 'service': serviceId},
      );
      final data = res.data as Map<String, dynamic>;
      final slots = (data['slots'] as List)
          .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return StaffAvailabilityResult.success(
        data['date'] as String? ?? date,
        slots,
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return StaffAvailabilityResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  /// Exactly one of [clientId] or [client] is required — mirrors the
  /// backend's own "provide exactly one" validation.
  Future<StaffBookingCreateResult> createBooking({
    String? clientId,
    Map<String, String>? client,
    required String serviceId,
    required String scheduledStart,
  }) async {
    assert(
      (clientId != null) != (client != null),
      'createBooking needs exactly one of clientId or client',
    );
    try {
      final res = await _dio.post(
        '/v1/staff/bookings',
        data: {
          if (clientId != null) 'clientId': clientId,
          if (client != null) 'client': client,
          'serviceId': serviceId,
          'scheduledStart': scheduledStart,
        },
      );
      final booking = res.data['booking'] as Map<String, dynamic>;
      return StaffBookingCreateResult.success(booking['id'] as String);
    } on DioException catch (e) {
      final err = _errorFrom(e);
      if (e.response?.statusCode == 409 && err.code == 'slot_taken') {
        final data = e.response?.data as Map;
        final slots = (data['slots'] as List? ?? [])
            .map((s) => SlotModel.fromJson(s as Map<String, dynamic>))
            .toList();
        return StaffBookingCreateResult.slotTaken(
          err.message ?? 'That time was just taken.',
          slots,
        );
      }
      return StaffBookingCreateResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
