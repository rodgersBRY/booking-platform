import '../../booking/models/slot_model.dart';

/// Result of POST /v1/staff/bookings. [slotTaken] follows the exact same
/// shape as BookingActionResult.slotTaken (customer reschedule) and
/// BookingSubmitResult.slotTaken (customer booking wizard) — the 409
/// conflict carries alternate slots so the caller can offer them inline
/// instead of a dead-end error.
///
/// Only [bookingId] is carried on success (not a full booking model): the
/// sole thing the create-booking flow does with the response is navigate
/// to BarberAppointmentDetailPage(bookingId: ...), which fetches its own
/// full detail by id anyway. Note the response's `booking` object is the
/// raw `bookings` table row from createBooking.ts (`.select().single()`),
/// so its id field is `id`, not `bookingId` — StaffBookingRepository reads
/// `booking['id']` accordingly.
class StaffBookingCreateResult {
  final bool success;
  final String? bookingId;
  final String? errorCode;
  final String? message;
  final List<SlotModel>? slots;

  StaffBookingCreateResult.success(this.bookingId)
    : success = true,
      errorCode = null,
      message = null,
      slots = null;

  StaffBookingCreateResult.slotTaken(this.message, this.slots)
    : success = false,
      bookingId = null,
      errorCode = 'slot_taken';

  StaffBookingCreateResult.failure(this.errorCode, this.message)
    : success = false,
      bookingId = null,
      slots = null;
}
