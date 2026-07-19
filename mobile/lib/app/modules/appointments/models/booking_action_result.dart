import 'booking_model.dart';
import '../../booking/models/slot_model.dart';

/// Shared result type for cancel/reschedule — follows the same
/// named-constructor pattern as AuthResult/BookingSubmitResult. Cancel
/// never populates [booking] or [slots] on success.
class BookingActionResult {
  final bool success;
  final BookingModel? booking;
  final String? errorCode;
  final String? message;
  final List<SlotModel>? slots;

  BookingActionResult.success([this.booking])
    : success = true,
      errorCode = null,
      message = null,
      slots = null;

  BookingActionResult.slotTaken(this.message, this.slots)
    : success = false,
      booking = null,
      errorCode = 'slot_taken';

  BookingActionResult.failure(this.errorCode, this.message)
    : success = false,
      booking = null,
      slots = null;
}
