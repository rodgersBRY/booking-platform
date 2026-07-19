import 'staff_appointment_model.dart';

/// Result of GET /v1/staff/schedule?range=today|tomorrow|week — same
/// named-constructor pattern as StaffDayResult so StaffScheduleRepository
/// never lets a raw DioException reach BarberScheduleController.
class StaffScheduleResult {
  final bool success;
  final String? range;
  final List<StaffAppointmentModel>? schedule;
  final String? errorCode;
  final String? message;

  StaffScheduleResult.success(this.range, this.schedule)
    : success = true,
      errorCode = null,
      message = null;

  StaffScheduleResult.failure(this.errorCode, this.message)
    : success = false,
      range = null,
      schedule = null;
}
