import 'package:get/get.dart';

import 'models/staff_customer_profile_model.dart';
import 'repositories/staff_customers_repository.dart';

/// Drives the barber "Customer Profile" screen — fetches one client by id
/// (GET /v1/staff/clients/[id]) per BARBER-APP.md's "Customer Profile"
/// section.
///
/// One instance per customer id (see BarberCustomerProfilePage, which
/// tags it by id) rather than a shared GetView singleton — mirrors
/// BarberAppointmentDetailController: a barber can open several different
/// customers' profiles across a session and each needs its own state.
class BarberCustomerProfileController extends GetxController {
  final String customerId;
  BarberCustomerProfileController(this.customerId);

  final StaffCustomersRepository _repo = StaffCustomersRepository();

  final loading = true.obs;
  final profile = Rxn<StaffCustomerProfileModel>();
  final loadError = RxnString();

  /// True only when the load failed because this staff member never
  /// served the client (403/404) — the page shows a distinct,
  /// non-retryable message for this case rather than the usual
  /// "couldn't load, try again" error state.
  final notServed = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    loadError.value = null;
    notServed.value = false;

    final result = await _repo.fetchCustomerProfile(customerId);
    loading.value = false;

    if (result.success) {
      profile.value = result.profile;
      return;
    }
    notServed.value = result.notServed;
    loadError.value = result.message;
  }
}
