import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../booking/models/service_model.dart';
import '../../booking/models/slot_model.dart';
import '../barber_appointment_detail_page.dart';
import '../barber_dashboard_controller.dart';
import '../barber_schedule_controller.dart';
import '../models/staff_client_model.dart';
import '../repositories/staff_booking_repository.dart';
import 'pages/date_page.dart';
import 'pages/review_page.dart';
import 'pages/service_page.dart';
import 'pages/time_page.dart';

/// The barber create-booking wizard's steps, in order — its own enum
/// rather than reusing the customer wizard's BookingStep (see
/// booking_progress_indicator.dart): no "professional" step here, since
/// staffId is always the calling barber, and "customer" replaces
/// "category" as the first step. Both wizards drive the same
/// BookingProgressIndicator via its enum-agnostic currentStep/totalSteps
/// ints.
enum BarberBookingStep { customer, service, date, time, review }

/// Drives the barber-initiated "create a booking for a client" wizard —
/// Customer, Service, Date, Time, Review, per Slice 4 of
/// docs/superpowers/specs/2026-07-18-barber-workspace-design.md.
///
/// One controller shared across all five step pages, registered with
/// fenix in BarberShellBinding alongside the other three barber tab
/// controllers. Pages are pushed with Get.to() rather than named
/// app_routes entries — this mirrors how BarberAppointmentDetailPage is
/// already reached from this module (see barber_schedule_page.dart /
/// barber_dashboard_page.dart), rather than the customer booking wizard's
/// named-route-per-step pattern. The wizard is only ever entered from the
/// Schedule tab's FAB, never deep-linked or reachable any other way, so it
/// doesn't need a place in the global route table the way the customer
/// flow (reachable from Home's category shortcuts too) does.
class BarberCreateBookingController extends GetxController {
  final StaffBookingRepository _repo = StaffBookingRepository();

  // ── Step 1: customer ────────────────────────────────────────────────────
  final clientSearchController = TextEditingController();
  final clientQuery = ''.obs;
  final clientResults = <StaffClientModel>[].obs;
  final clientSearchLoading = false.obs;
  final clientSearchError = RxnString();
  final Rxn<StaffClientModel> selectedClient = Rxn<StaffClientModel>();
  Timer? _searchDebounce;

  // Quick "new client" registration, offered inline once a search comes up
  // empty — BARBER-APP.md: "Name, Phone Number. Nothing else is required."
  final newClientName = ''.obs;
  final newClientPhone = ''.obs;
  final newClientSubmitting = false.obs;
  final newClientError = RxnString();

  // ── Step 2: service ──────────────────────────────────────────────────────
  final services = <ServiceModel>[].obs;
  final servicesLoading = true.obs;
  final servicesError = RxnString();
  final Rxn<ServiceModel> selectedService = Rxn<ServiceModel>();

  // ── Step 3: date ─────────────────────────────────────────────────────────
  final RxString selectedDate = ''.obs;

  // ── Step 4: time ─────────────────────────────────────────────────────────
  final slots = <SlotModel>[].obs;
  final slotsLoading = false.obs;
  final slotsError = RxnString();
  final Rxn<SlotModel> selectedSlot = Rxn<SlotModel>();

  // ── Step 5: review / submit ─────────────────────────────────────────────
  final submitting = false.obs;
  final submitError = RxnString();
  final slotTakenSlots = Rxn<List<SlotModel>>();

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    clientSearchController.dispose();
    super.onClose();
  }

  /// Clears every field back to a fresh wizard run. The controller is kept
  /// alive (fenix) for the whole barber-shell session, so without this a
  /// second "New Booking" would silently resume the previous run's
  /// selections. Called from the Schedule tab's FAB before pushing the
  /// first step.
  void reset() {
    _searchDebounce?.cancel();
    clientSearchController.clear();
    clientQuery.value = '';
    clientResults.clear();
    clientSearchLoading.value = false;
    clientSearchError.value = null;
    selectedClient.value = null;
    newClientName.value = '';
    newClientPhone.value = '';
    newClientSubmitting.value = false;
    newClientError.value = null;
    selectedService.value = null;
    selectedDate.value = '';
    slots.clear();
    slotsLoading.value = false;
    slotsError.value = null;
    selectedSlot.value = null;
    submitting.value = false;
    submitError.value = null;
    slotTakenSlots.value = null;
  }

  // ── Step 1: customer ─────────────────────────────────────────────────────

  /// Debounced server search. The backend floors queries under 2 chars to
  /// an empty result (searchClients.ts), so there's no point firing a
  /// request for those — just clear any stale results instead.
  void onClientQueryChanged(String value) {
    clientQuery.value = value;
    _searchDebounce?.cancel();
    if (value.trim().length < 2) {
      clientResults.clear();
      clientSearchLoading.value = false;
      clientSearchError.value = null;
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchClients(value.trim());
    });
  }

  Future<void> _searchClients(String query) async {
    clientSearchLoading.value = true;
    clientSearchError.value = null;
    final result = await _repo.searchClients(query);
    // A newer keystroke may have already fired its own search — don't let
    // a slow, stale response clobber it.
    if (clientQuery.value.trim() != query) return;
    clientSearchLoading.value = false;
    if (result.success) {
      clientResults.value = result.clients ?? [];
    } else {
      clientResults.clear();
      clientSearchError.value = result.message;
    }
  }

  void selectClient(StaffClientModel client) {
    selectedClient.value = client;
    Get.to(() => const ServicePage());
  }

  Future<void> submitNewClient() async {
    final name = newClientName.value.trim();
    final phone = newClientPhone.value.trim();
    if (name.isEmpty || phone.isEmpty) {
      newClientError.value = 'Please enter a name and phone number.';
      return;
    }
    newClientSubmitting.value = true;
    newClientError.value = null;
    final result = await _repo.createClient(name: name, phone: phone);
    newClientSubmitting.value = false;
    if (result.success) {
      selectedClient.value = result.client;
      Get.to(() => const ServicePage());
      return;
    }
    newClientError.value =
        result.message ?? 'Something went wrong. Please try again.';
  }

  // ── Step 2: service ──────────────────────────────────────────────────────

  Future<void> loadServices() async {
    servicesLoading.value = true;
    servicesError.value = null;
    final result = await _repo.fetchServices();
    servicesLoading.value = false;
    if (result.success) {
      services.value = result.services ?? [];
    } else {
      servicesError.value = result.message;
    }
  }

  void selectService(ServiceModel service) {
    selectedService.value = service;
    selectedSlot.value = null;
    Get.to(() => const DatePage());
  }

  // ── Step 3: date ─────────────────────────────────────────────────────────

  /// Next [count] calendar dates as "YYYY-MM-DD" strings, starting today —
  /// same shape BookingController.nextDates uses for the customer wizard.
  List<String> nextDates(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = now.add(Duration(days: i));
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '${d.year}-$m-$day';
    });
  }

  void selectDate(String date) {
    selectedDate.value = date;
    selectedSlot.value = null;
    Get.to(() => const TimePage());
    loadSlots(date);
  }

  // ── Step 4: time ─────────────────────────────────────────────────────────

  Future<void> loadSlots(String date) async {
    final serviceId = selectedService.value?.id;
    if (serviceId == null) return;
    slots.clear();
    slotsError.value = null;
    slotsLoading.value = true;
    final result = await _repo.fetchAvailability(
      date: date,
      serviceId: serviceId,
    );
    slotsLoading.value = false;
    if (result.success) {
      slots.value = result.slots ?? [];
    } else {
      slotsError.value = result.message;
    }
  }

  void selectSlot(SlotModel slot) {
    selectedSlot.value = slot;
    slotTakenSlots.value = null;
    submitError.value = null;
    Get.to(() => const ReviewPage());
  }

  /// Swaps the selected slot without navigating — used by the "slot taken,
  /// pick another" retry list shown inline on the Review page.
  void retrySlot(SlotModel slot) {
    selectedSlot.value = slot;
    slotTakenSlots.value = null;
    submitError.value = null;
  }

  // ── Step 5: review / submit ─────────────────────────────────────────────

  Future<void> submit() async {
    final client = selectedClient.value;
    final service = selectedService.value;
    final slot = selectedSlot.value;
    if (client == null || service == null || slot == null) return;

    submitting.value = true;
    submitError.value = null;
    slotTakenSlots.value = null;

    final result = await _repo.createBooking(
      clientId: client.id,
      serviceId: service.id,
      scheduledStart: slot.start,
    );

    submitting.value = false;

    if (result.success) {
      final bookingId = result.bookingId!;
      _refreshSiblingScreens();
      // Pop the whole wizard stack back down to the shell, then push
      // straight into the new booking's own detail page. There's no
      // dedicated "Booked!" screen in this flow (see
      // StaffBookingCreateResult's doc comment) — the detail page fetches
      // its own full booking by id, so a summary screen here would just
      // be a second fetch away from the same information.
      Get.until((route) => route.settings.name == AppRoutes.barberShell);
      Get.to(() => BarberAppointmentDetailPage(bookingId: bookingId));
      return;
    }

    if (result.errorCode == 'slot_taken') {
      submitError.value = result.message ?? 'That time was just taken.';
      slotTakenSlots.value = result.slots;
      return;
    }

    submitError.value =
        result.message ?? 'Something went wrong. Please try again.';
  }

  /// The Dashboard and Schedule tabs stay mounted (IndexedStack) under the
  /// wizard the whole time it's pushed on top, so their usual "tab
  /// regained focus" refresh never fires on the way back — nudge them
  /// explicitly, same rationale as
  /// BarberAppointmentDetailController._refreshSiblingScreens.
  void _refreshSiblingScreens() {
    if (Get.isRegistered<BarberDashboardController>()) {
      Get.find<BarberDashboardController>().refreshDay();
    }
    if (Get.isRegistered<BarberScheduleController>()) {
      Get.find<BarberScheduleController>().refreshSchedule();
    }
  }
}
