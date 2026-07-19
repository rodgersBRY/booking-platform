import 'package:get/get.dart';

import 'models/booking_detail_model.dart';
import 'repositories/staff_schedule_repository.dart';
import 'barber_dashboard_controller.dart';
import 'barber_schedule_controller.dart';

/// Drives the barber's appointment-detail working screen — fetches one
/// booking by id (GET /v1/staff/bookings/[id]), and owns notes editing
/// plus the start/complete primary action per BARBER-APP.md's
/// "Appointment Details" section.
///
/// One instance per booking id (see BarberAppointmentDetailPage, which
/// tags it by id) rather than a shared GetView singleton — a barber can
/// open several different bookings' details across a session and each
/// needs its own state.
class BarberAppointmentDetailController extends GetxController {
  final String bookingId;
  BarberAppointmentDetailController(this.bookingId);

  final StaffScheduleRepository _repo = StaffScheduleRepository();

  final loading = true.obs;
  final booking = Rxn<BookingDetailModel>();
  final loadError = RxnString();

  final savingCustomerNotes = false.obs;
  final savingStaffNotes = false.obs;

  final starting = false.obs;
  final completing = false.obs;

  /// Set after a failed start/complete action so the caller can surface
  /// it once (snackbar), then re-check for the next attempt.
  final actionError = RxnString();

  /// True only when [actionError] came from the start endpoint's 409
  /// `staff_busy` conflict — lets the UI offer a retry instead of
  /// treating it as a dead-end failure.
  final staffBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    loadError.value = null;
    try {
      final result = await _repo.fetchBookingDetail(bookingId);
      if (result.success) {
        booking.value = result.booking;
      } else {
        loadError.value = result.message;
      }
    } finally {
      loading.value = false;
    }
  }

  /// Returns null on success, or a user-facing error message on failure —
  /// lets the caller (the notes section's inline "Save" action) show the
  /// specific failure instead of just silently staying in edit mode.
  Future<String?> saveCustomerNotes(String value) async {
    savingCustomerNotes.value = true;
    final result = await _repo.updateBookingNotes(
      bookingId,
      customerNotes: value,
    );
    savingCustomerNotes.value = false;

    if (result.success) {
      final current = booking.value;
      if (current != null) {
        booking.value = current.copyWith(
          customerNotes: result.customerNotes ?? value,
        );
      }
      return null;
    }
    return result.message;
  }

  /// See [saveCustomerNotes] — same null-on-success/message-on-failure
  /// contract.
  Future<String?> saveStaffNotes(String value) async {
    savingStaffNotes.value = true;
    final result = await _repo.updateBookingNotes(bookingId, staffNotes: value);
    savingStaffNotes.value = false;

    if (result.success) {
      final current = booking.value;
      if (current != null) {
        booking.value = current.copyWith(staffNotes: result.staffNotes ?? value);
      }
      return null;
    }
    return result.message;
  }

  Future<void> startService() async {
    if (starting.value) return;
    starting.value = true;
    actionError.value = null;
    staffBusy.value = false;

    final result = await _repo.startBooking(bookingId);
    starting.value = false;

    if (result.success) {
      booking.value = result.booking;
      _refreshSiblingScreens();
    } else {
      actionError.value = result.message;
      staffBusy.value = result.staffBusy;
    }
  }

  Future<bool> completeService({String? notes}) async {
    if (completing.value) return false;
    completing.value = true;
    actionError.value = null;
    staffBusy.value = false;

    final result = await _repo.completeBooking(bookingId, notes: notes);
    completing.value = false;

    if (result.success) {
      final current = booking.value;
      if (current != null) {
        booking.value = current.copyWith(
          status: 'completed',
          canStart: false,
          canComplete: false,
        );
      }
      _refreshSiblingScreens();
      return true;
    }
    actionError.value = result.message;
    return false;
  }

  /// The Dashboard and Schedule tabs stay mounted (IndexedStack) the whole
  /// time this detail page is pushed on top of them, so neither one's
  /// usual "tab regained focus" refresh trigger fires on the way back —
  /// nudge them explicitly, same rationale as AppointmentDetailPage's
  /// post-cancel HomeController refresh in the customer module.
  void _refreshSiblingScreens() {
    if (Get.isRegistered<BarberDashboardController>()) {
      Get.find<BarberDashboardController>().refreshDay();
    }
    if (Get.isRegistered<BarberScheduleController>()) {
      Get.find<BarberScheduleController>().refreshSchedule();
    }
  }
}
