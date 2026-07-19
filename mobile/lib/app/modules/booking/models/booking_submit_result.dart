import 'slot_model.dart';

class BookingSubmitResult {
  final bool success;
  final Map<String, dynamic>? booking;
  final String? errorCode;
  final String? message;
  final List<SlotModel>? slots;

  BookingSubmitResult.success(this.booking)
    : success = true,
      errorCode = null,
      message = null,
      slots = null;

  BookingSubmitResult.slotTaken(this.message, this.slots)
    : success = false,
      booking = null,
      errorCode = 'slot_taken';

  BookingSubmitResult.failure(this.errorCode, this.message)
    : success = false,
      booking = null,
      slots = null;
}
