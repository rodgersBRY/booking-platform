import 'package:get/get.dart';

import '../login/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_toast.dart';

class SignupController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final name = ''.obs;
  final phone = ''.obs;
  final email = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final submitting = false.obs;

  Future<void> submit() async {
    if (name.value.trim().isEmpty ||
        phone.value.trim().isEmpty ||
        email.value.trim().isEmpty ||
        password.value.isEmpty) {
      AppToast.error('Please fill in every field.');
      return;
    }
    if (password.value.length < 8) {
      AppToast.error('Password must be at least 8 characters.');
      return;
    }
    if (password.value != confirmPassword.value) {
      AppToast.error('Passwords don\'t match.');
      return;
    }

    submitting.value = true;

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
      // No session yet — the account needs email confirmation first, so
      // send them to sign in once they've confirmed instead of leaving them
      // stranded on the signup form.
      Get.offAllNamed(AppRoutes.login);
      AppToast.success(
        result.message ?? 'Check your email to confirm your account.',
      );
      return;
    }

    AppToast.error(result.message ?? 'Something went wrong. Please try again.');
  }
}
