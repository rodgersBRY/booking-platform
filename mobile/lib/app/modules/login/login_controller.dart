import 'package:get/get.dart';

import 'repositories/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_toast.dart';

class LoginController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final email = ''.obs;
  final password = ''.obs;
  final submitting = false.obs;

  Future<void> submit() async {
    if (email.value.trim().isEmpty || password.value.isEmpty) {
      AppToast.error('Enter your email and password.');
      return;
    }

    submitting.value = true;

    final result = await _repo.login(
      email: email.value.trim(),
      password: password.value,
    );

    submitting.value = false;

    if (result.success) {
      Get.offAllNamed(result.isStaff ? AppRoutes.barberShell : AppRoutes.shell);
      
      return;
    }

    AppToast.error(result.message ?? 'Something went wrong. Please try again.');
  }
}
