import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class LoginController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final email = ''.obs;
  final password = ''.obs;
  final submitting = false.obs;
  final errorMessage = RxnString();

  Future<void> submit() async {
    if (email.value.trim().isEmpty || password.value.isEmpty) {
      errorMessage.value = 'Enter your email and password.';
      return;
    }

    submitting.value = true;
    errorMessage.value = null;

    final result = await _repo.login(
      email: email.value.trim(),
      password: password.value,
    );

    submitting.value = false;

    if (result.success) {
      Get.offAllNamed(AppRoutes.account);
      return;
    }

    errorMessage.value = result.message ?? 'Something went wrong. Please try again.';
  }
}
