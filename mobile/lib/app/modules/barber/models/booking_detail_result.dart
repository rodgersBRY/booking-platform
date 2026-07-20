import 'booking_detail_model.dart';

/// Result of GET /v1/staff/bookings/[id].
class BookingDetailResult {
  final bool success;
  final BookingDetailModel? booking;
  final String? errorCode;
  final String? message;

  BookingDetailResult.success(this.booking)
    : success = true,
      errorCode = null,
      message = null;

  BookingDetailResult.failure(this.errorCode, this.message)
    : success = false,
      booking = null;
}

/// Result of PATCH /v1/staff/bookings/[id] (notes only). The endpoint
/// echoes back both notes fields regardless of which one was sent, so the
/// caller can always resync from [customerNotes]/[staffNotes] on success.
class BookingNotesResult {
  final bool success;
  final String? customerNotes;
  final String? staffNotes;
  final String? errorCode;
  final String? message;

  BookingNotesResult.success(this.customerNotes, this.staffNotes)
    : success = true,
      errorCode = null,
      message = null;

  BookingNotesResult.failure(this.errorCode, this.message)
    : success = false,
      customerNotes = null,
      staffNotes = null;
}

/// Result of POST /v1/staff/bookings/[id]/start. [staffBusy] is its own
/// named constructor (not folded into [failure]) so
/// BarberAppointmentDetailController can tell the 409 "the barber is
/// already with another client" conflict apart from any other failure and
/// offer a retry instead of a dead-end error — mirrors
/// BookingActionResult.slotTaken in the customer appointments module.
class BookingStartResult {
  final bool success;
  final BookingDetailModel? booking;
  final bool staffBusy;
  final String? errorCode;
  final String? message;

  BookingStartResult.success(this.booking)
    : success = true,
      staffBusy = false,
      errorCode = null,
      message = null;

  BookingStartResult.staffBusy(this.message)
    : success = false,
      booking = null,
      staffBusy = true,
      errorCode = 'staff_busy';

  BookingStartResult.failure(this.errorCode, this.message)
    : success = false,
      booking = null,
      staffBusy = false;
}

/// Result of POST /v1/staff/bookings/[id]/complete. The response's
/// `visit` payload shape isn't pinned down by the backend contract beyond
/// "an object", so this result deliberately doesn't try to parse it —
/// BarberAppointmentDetailController applies the completed state to its
/// already-loaded BookingDetailModel locally on success instead.
class BookingCompleteResult {
  final bool success;
  final String? errorCode;
  final String? message;

  BookingCompleteResult.success()
    : success = true,
      errorCode = null,
      message = null;

  BookingCompleteResult.failure(this.errorCode, this.message) : success = false;
}
