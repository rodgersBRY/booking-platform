import 'package:get/get.dart';

import '../../data/models/client_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class AccountController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final loading = true.obs;
  final Rxn<ClientModel> client = Rxn<ClientModel>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final me = await _repo.fetchMe();
    loading.value = false;

    if (me == null) {
      // No valid session — back to sign in.
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    client.value = me;
  }

  Future<void> signOut() async {
    await _repo.logout();
    Get.offAllNamed(AppRoutes.welcome);
  }
}
