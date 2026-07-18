import 'package:get/get.dart';

import 'barber_profile_controller.dart';
import 'barber_shell_controller.dart';

class BarberShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BarberShellController>(() => BarberShellController());
    Get.lazyPut<BarberProfileController>(
      () => BarberProfileController(),
      fenix: true,
    );
  }
}
