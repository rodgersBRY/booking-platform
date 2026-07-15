import 'package:get/get.dart';

import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class SignupController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final name = ''.obs;
  final phone = ''.obs;
  final email = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final submitting = false.obs;
  final errorMessage = RxnString();
  final successMessage = RxnString();

  Future<void> submit() async {
    if (name.value.trim().isEmpty ||
        phone.value.trim().isEmpty ||
        email.value.trim().isEmpty ||
        password.value.isEmpty) {
      errorMessage.value = 'Please fill in every field.';
      return;
    }
    if (password.value.length < 8) {
      errorMessage.value = 'Password must be at least 8 characters.';
      return;
    }
    if (password.value != confirmPassword.value) {
      errorMessage.value = 'Passwords don\'t match.';
      return;
    }

    submitting.value = true;
    errorMessage.value = null;
    successMessage.value = null;

    final result = await _repo.signup(
      name: name.value.trim(),
      phone: phone.value.trim(),
      email: email.value.trim(),
      password: password.value,
    );

    submitting.value = false;

    if (result.success) {
      Get.offAllNamed(AppRoutes.shell);
      return;
    }

    if (result.pendingConfirmation) {
      successMessage.value =
          result.message ?? 'Check your email to confirm your account.';
      return;
    }

    errorMessage.value = result.message ?? 'Something went wrong. Please try again.';
  }
}
