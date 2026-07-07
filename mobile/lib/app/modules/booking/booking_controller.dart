import 'package:get/get.dart';

import '../../data/models/service_model.dart';
import '../../data/models/slot_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../routes/app_routes.dart';

const anyStaffId = 'any';

class BookingController extends GetxController {
  final BookingRepository _repo = BookingRepository();

  // ── Step 1: service ──────────────────────────────────────────────────────
  final services = <ServiceModel>[].obs;
  final servicesLoading = true.obs;
  final servicesError = RxnString();
  final Rxn<ServiceModel> selectedService = Rxn<ServiceModel>();

  // ── Step 2: staff ────────────────────────────────────────────────────────
  final staff = <StaffModel>[].obs;
  final staffLoading = true.obs;
  final staffError = RxnString();
  final RxnString selectedStaffId = RxnString();

  // ── Step 3: date + slot ──────────────────────────────────────────────────
  final RxString activeDate = ''.obs;
  final slots = <SlotModel>[].obs;
  final slotsLoading = false.obs;
  final slotsError = RxnString();
  final Rxn<SlotModel> selectedSlot = Rxn<SlotModel>();

  // ── Step 4: details ──────────────────────────────────────────────────────
  final name = ''.obs;
  final phone = ''.obs;
  final submitting = false.obs;
  final submitError = RxnString();
  final slotTakenSlots = Rxn<List<SlotModel>>();

  // ── Result ───────────────────────────────────────────────────────────────
  final Rxn<Map<String, dynamic>> confirmedBooking = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    loadServices();
    loadStaff();
  }

  Future<void> loadServices() async {
    servicesLoading.value = true;
    servicesError.value = null;
    try {
      services.value = await _repo.fetchServices();
    } catch (_) {
      servicesError.value = "Couldn't load services. Please try again.";
    } finally {
      servicesLoading.value = false;
    }
  }

  Future<void> loadStaff() async {
    staffLoading.value = true;
    staffError.value = null;
    try {
      staff.value = await _repo.fetchStaff();
    } catch (_) {
      staffError.value = "Couldn't load staff. Please try again.";
    } finally {
      staffLoading.value = false;
    }
  }

  void selectService(ServiceModel service) {
    selectedService.value = service;
    Get.toNamed(AppRoutes.bookStaff);
  }

  void selectStaff(String staffId) {
    selectedStaffId.value = staffId;
    selectedSlot.value = null;
    Get.toNamed(AppRoutes.bookSlot);
    loadSlots(nextDates(14).first);
  }

  /// Next [count] calendar dates as "YYYY-MM-DD" strings, starting today.
  List<String> nextDates(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = now.add(Duration(days: i));
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '${d.year}-$m-$day';
    });
  }

  Future<void> loadSlots(String date) async {
    if (selectedService.value == null || selectedStaffId.value == null) return;
    activeDate.value = date;
    slots.clear();
    slotsError.value = null;
    slotsLoading.value = true;
    try {
      slots.value = await _repo.fetchAvailability(
        staffId: selectedStaffId.value!,
        serviceId: selectedService.value!.id,
        date: date,
      );
    } catch (_) {
      slotsError.value = "Couldn't load times. Please try again.";
    } finally {
      slotsLoading.value = false;
    }
  }

  void selectSlot(SlotModel slot) {
    selectedSlot.value = slot;
    slotTakenSlots.value = null;
    submitError.value = null;
    Get.toNamed(AppRoutes.bookDetails);
  }

  /// Swap the selected slot without navigating — used by the "slot taken,
  /// pick another" retry list shown inline on the details page.
  void retrySlot(SlotModel slot) {
    selectedSlot.value = slot;
    slotTakenSlots.value = null;
    submitError.value = null;
  }

  Future<void> submit() async {
    if (selectedService.value == null || selectedSlot.value == null) return;
    if (name.value.trim().isEmpty || phone.value.trim().isEmpty) {
      submitError.value = 'Please enter your name and phone number.';
      return;
    }

    submitting.value = true;
    submitError.value = null;
    slotTakenSlots.value = null;

    final result = await _repo.createBooking(
      name: name.value.trim(),
      phone: phone.value.trim(),
      staffId: selectedSlot.value!.staffId,
      serviceId: selectedService.value!.id,
      scheduledStart: selectedSlot.value!.start,
    );

    submitting.value = false;

    if (result.success) {
      confirmedBooking.value = result.booking;
      // Clear the whole wizard stack — back from confirmation shouldn't
      // step back through service/staff/slot/details.
      Get.offAllNamed(AppRoutes.bookConfirmation);
      return;
    }

    if (result.errorCode == 'slot_taken') {
      submitError.value = result.message ?? 'That time was just taken.';
      slotTakenSlots.value = result.slots;
      return;
    }

    submitError.value = result.message ?? 'Something went wrong. Please try again.';
  }

  /// Reset all state and start a fresh booking.
  void startOver() {
    selectedService.value = null;
    selectedStaffId.value = null;
    selectedSlot.value = null;
    slots.clear();
    activeDate.value = '';
    name.value = '';
    phone.value = '';
    submitError.value = null;
    slotTakenSlots.value = null;
    confirmedBooking.value = null;
    Get.offAllNamed(AppRoutes.bookService);
  }
}
