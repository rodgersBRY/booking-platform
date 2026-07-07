import 'package:get/get.dart';

/// Stub controller — the account/login backend hasn't been built yet.
/// Wire this up to a real endpoint once client auth exists server-side.
class LoginController extends GetxController {
  final email = ''.obs;
  final password = ''.obs;

  void submit() {
    Get.snackbar(
      'Coming soon',
      'Account sign-in isn\'t available yet — use "Continue as guest" for now.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
