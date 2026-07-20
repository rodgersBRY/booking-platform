import 'package:get/get.dart';

import 'barber_customers_controller.dart';
import 'barber_dashboard_controller.dart';
import 'barber_notifications_controller.dart';
import 'barber_profile_controller.dart';
import 'barber_schedule_controller.dart';
import 'barber_shell_controller.dart';
import 'create_booking/barber_create_booking_controller.dart';

class BarberShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BarberShellController>(() => BarberShellController());
    Get.lazyPut<BarberDashboardController>(
      () => BarberDashboardController(),
      fenix: true,
    );
    Get.lazyPut<BarberScheduleController>(
      () => BarberScheduleController(),
      fenix: true,
    );
    Get.lazyPut<BarberCustomersController>(
      () => BarberCustomersController(),
      fenix: true,
    );
    Get.lazyPut<BarberNotificationsController>(
      () => BarberNotificationsController(),
      fenix: true,
    );
    Get.lazyPut<BarberProfileController>(
      () => BarberProfileController(),
      fenix: true,
    );
    Get.lazyPut<BarberCreateBookingController>(
      () => BarberCreateBookingController(),
      fenix: true,
    );
  }
}
