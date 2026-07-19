import '../../booking/models/slot_model.dart';

/// Result of GET /v1/staff/availability?date=&service= — reuses the
/// customer booking flow's SlotModel directly since the backend contract
/// describes the same response shape.
class StaffAvailabilityResult {
  final bool success;
  final String? date;
  final List<SlotModel>? slots;
  final String? errorCode;
  final String? message;

  StaffAvailabilityResult.success(this.date, this.slots)
    : success = true,
      errorCode = null,
      message = null;

  StaffAvailabilityResult.failure(this.errorCode, this.message)
    : success = false,
      date = null,
      slots = null;
}
