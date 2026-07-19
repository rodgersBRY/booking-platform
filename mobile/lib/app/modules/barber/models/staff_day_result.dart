import 'staff_day_model.dart';

/// Result of GET /v1/staff/day — named-constructor pattern shared with
/// AuthResult/BookingActionResult, so StaffDayRepository never lets a raw
/// DioException reach BarberDashboardController.
class StaffDayResult {
  final bool success;
  final StaffDayModel? day;
  final String? errorCode;
  final String? message;

  StaffDayResult.success(this.day)
    : success = true,
      errorCode = null,
      message = null;

  StaffDayResult.failure(this.errorCode, this.message)
    : success = false,
      day = null;
}
