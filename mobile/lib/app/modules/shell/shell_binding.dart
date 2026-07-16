import 'package:get/get.dart';

import '../home/home_controller.dart';
import 'shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController());
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
