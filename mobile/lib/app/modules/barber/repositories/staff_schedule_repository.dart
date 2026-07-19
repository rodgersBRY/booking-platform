import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../models/booking_detail_model.dart';
import '../models/booking_detail_result.dart';
import '../models/staff_appointment_model.dart';
import '../models/staff_schedule_result.dart';

/// The barber's schedule and per-booking working screen —
/// /v1/staff/schedule and /v1/staff/bookings/[id]* on the same backend
/// StaffDayRepository talks to. Mirrors its DioException-to-result
/// mapping throughout so controllers never see a raw Dio error.
class StaffScheduleRepository {
  Dio get _dio => Get.find<ApiService>().dio;

  ({String? code, String? message}) _errorFrom(DioException e) {
    final data = e.response?.data;
    return (
      code: data is Map ? data['error'] as String? : null,
      message: data is Map ? data['message'] as String? : null,
    );
  }

  Future<StaffScheduleResult> fetchSchedule(String range) async {
    try {
      final res = await _dio.get(
        '/v1/staff/schedule',
        queryParameters: {'range': range},
      );
      final data = res.data as Map<String, dynamic>;
      final schedule =
          (data['schedule'] as List)
              .map(
                (e) =>
                    StaffAppointmentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
      return StaffScheduleResult.success(
        data['range'] as String? ?? range,
        schedule,
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return StaffScheduleResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<BookingDetailResult> fetchBookingDetail(String id) async {
    try {
      final res = await _dio.get('/v1/staff/bookings/$id');
      return BookingDetailResult.success(
        BookingDetailModel.fromJson(res.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return BookingDetailResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<BookingNotesResult> updateBookingNotes(
    String id, {
    String? customerNotes,
    String? staffNotes,
  }) async {
    assert(
      customerNotes != null || staffNotes != null,
      'updateBookingNotes needs at least one of customerNotes/staffNotes',
    );
    try {
      final res = await _dio.patch(
        '/v1/staff/bookings/$id',
        data: {
          if (customerNotes != null) 'customerNotes': customerNotes,
          if (staffNotes != null) 'staffNotes': staffNotes,
        },
      );
      return BookingNotesResult.success(
        res.data['customerNotes'] as String?,
        res.data['staffNotes'] as String?,
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return BookingNotesResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<BookingStartResult> startBooking(String id) async {
    try {
      final res = await _dio.post('/v1/staff/bookings/$id/start');
      return BookingStartResult.success(
        BookingDetailModel.fromJson(
          res.data['booking'] as Map<String, dynamic>,
        ),
      );
    } on DioException catch (e) {
      final err = _errorFrom(e);
      if (e.response?.statusCode == 409 && err.code == 'staff_busy') {
        return BookingStartResult.staffBusy(
          err.message ?? 'That barber is busy right now.',
        );
      }
      return BookingStartResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<BookingCompleteResult> completeBooking(
    String id, {
    String? notes,
  }) async {
    try {
      await _dio.post(
        '/v1/staff/bookings/$id/complete',
        data: {if (notes != null && notes.trim().isNotEmpty) 'notes': notes},
      );
      return BookingCompleteResult.success();
    } on DioException catch (e) {
      final err = _errorFrom(e);
      return BookingCompleteResult.failure(
        err.code,
        err.message ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
