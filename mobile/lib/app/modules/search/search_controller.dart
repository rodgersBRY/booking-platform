import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/service_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../routes/app_routes.dart';
import '../booking/booking_binding.dart';
import '../booking/booking_controller.dart';

/// Searches only real, already-fetched data — services, staff, and their
/// categories/roles. No hairstyle/beauty-inspiration content, since none
/// of that exists as data anywhere in the backend.
class AppSearchModuleController extends GetxController {
  final BookingRepository _repo = BookingRepository();
  final textController = TextEditingController();

  final query = ''.obs;
  final services = <ServiceModel>[].obs;
  final staff = <StaffModel>[].obs;
  final loading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([_repo.fetchServices(), _repo.fetchStaff()]);
      services.value = results[0] as List<ServiceModel>;
      staff.value = results[1] as List<StaffModel>;
    } catch (_) {
      error.value = "Couldn't load search results. Please try again.";
    } finally {
      loading.value = false;
    }
  }

  bool get hasQuery => query.value.trim().isNotEmpty;

  List<ServiceModel> get matchedServices {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return services
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.category?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  List<StaffModel> get matchedStaff {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return staff
        .where(
          (s) => s.name.toLowerCase().contains(q) || s.role.toLowerCase().contains(q),
        )
        .toList();
  }

  bool get hasResults => matchedServices.isNotEmpty || matchedStaff.isNotEmpty;

  BookingController _booking() {
    if (!Get.isRegistered<BookingController>()) {
      BookingBinding().dependencies();
    }
    return Get.find<BookingController>();
  }

  /// Matches HomeController.openService — jumps straight to the staff step
  /// for this service, category left unset (the review step already
  /// handles a null category gracefully).
  void openService(ServiceModel service) => _booking().selectService(service);

  /// The wizard needs a service before it can filter staff, so a
  /// professional result starts a fresh booking rather than pretending we
  /// can jump straight to them.
  void startBooking() => Get.toNamed(AppRoutes.bookCategory);
}
