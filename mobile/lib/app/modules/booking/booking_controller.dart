import 'package:get/get.dart';

import '../../data/models/service_model.dart';
import '../../data/models/slot_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../routes/app_routes.dart';

const anyStaffId = 'any';

/// Bucket key used for services with no category set.
const otherCategoryKey = '_other';

class BookingController extends GetxController {
  final BookingRepository _repo = BookingRepository();

  // ── Step 1: category, then service ──────────────────────────────────────
  final services = <ServiceModel>[].obs;
  final servicesLoading = true.obs;
  final servicesError = RxnString();
  final RxnString selectedCategory = RxnString();
  final Rxn<ServiceModel> selectedService = Rxn<ServiceModel>();

  /// Unique categories, in first-seen order, with uncategorized services
  /// bucketed under [otherCategoryKey] last.
  List<String> get categories {
    final seen = <String>[];
    var hasOther = false;
    for (final s in services) {
      final key = s.category;
      if (key == null || key.trim().isEmpty) {
        hasOther = true;
      } else if (!seen.contains(key)) {
        seen.add(key);
      }
    }
    if (hasOther) seen.add(otherCategoryKey);
    return seen;
  }

  List<ServiceModel> get servicesInSelectedCategory {
    final category = selectedCategory.value;
    if (category == null) return const [];
    if (category == otherCategoryKey) {
      return services.where((s) => s.category == null || s.category!.trim().isEmpty).toList();
    }
    return services.where((s) => s.category == category).toList();
  }

  // ── Step 2: staff ────────────────────────────────────────────────────────
  final staff = <StaffModel>[].obs;
  final staffLoading = true.obs;
  final staffError = RxnString();
  final RxnString selectedStaffId = RxnString();

  /// "Any barber" if every eligible staff member shares one role, else generic.
  String get anyStaffLabel {
    final roles = staff.map((s) => s.role).toSet();
    if (roles.length == 1) return 'Any ${roles.first}';
    return 'Any available staff';
  }

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

  /// Staff eligible for the currently selected service — call after
  /// [selectService]. No selected service means no staff to show.
  Future<void> loadStaffForSelectedService() async {
    final serviceId = selectedService.value?.id;
    if (serviceId == null) return;
    staffLoading.value = true;
    staffError.value = null;
    try {
      staff.value = await _repo.fetchStaff(serviceId: serviceId);
    } catch (_) {
      staffError.value = "Couldn't load staff. Please try again.";
    } finally {
      staffLoading.value = false;
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    Get.toNamed(AppRoutes.bookService);
  }

  void selectService(ServiceModel service) {
    selectedService.value = service;
    selectedStaffId.value = null;
    Get.toNamed(AppRoutes.bookStaff);
    loadStaffForSelectedService();
  }

  /// "Book Again" from a past appointment — seeds the category/service the
  /// client already had and jumps straight to picking a professional,
  /// skipping the category/service steps.
  void bookAgain(ServiceModel service) {
    selectedCategory.value = service.category;
    selectService(service);
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
    selectedCategory.value = null;
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
    Get.offAllNamed(AppRoutes.bookCategory);
  }
}
