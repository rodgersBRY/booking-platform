import 'package:get/get.dart';

import 'models/client_model.dart';
import '../login/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final loading = true.obs;
  final client = Rxn<ClientModel>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    client.value = await _repo.fetchMe();
    loading.value = false;
  }

  Future<void> signOut() async {
    await _repo.logout();
    client.value = null;
    Get.offAllNamed(AppRoutes.welcome);
  }
}
