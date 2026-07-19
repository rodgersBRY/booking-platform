import 'package:get/get.dart';

import '../../data/models/staff_account_model.dart';
import '../../data/repositories/staff_auth_repository.dart';
import '../../routes/app_routes.dart';

class BarberProfileController extends GetxController {
  final StaffAuthRepository _repo = StaffAuthRepository();

  final loading = true.obs;
  final staff = Rxn<StaffAccountModel>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    staff.value = await _repo.fetchMe();
    loading.value = false;
  }

  /// Clears the token and account type, then returns to the login screen.
  /// Unlike the customer profile's sign-out (which lands back on the
  /// welcome splash, since guest browsing is a valid customer state), the
  /// barber workspace has no guest mode — landing on welcome would just
  /// bounce straight into the customer shell instead of asking for a
  /// staff login again.
  Future<void> signOut() async {
    await _repo.logout();
    staff.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
