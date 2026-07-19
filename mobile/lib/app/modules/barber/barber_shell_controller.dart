import 'package:get/get.dart';

// Tab indices, kept as constants so other controllers can request a tab
// without magic numbers — mirrors shell_controller.dart's convention.
const barberDashboardTabIndex = 0;
const barberScheduleTabIndex = 1;
const barberCustomersTabIndex = 2;
const barberNotificationsTabIndex = 3;
const barberProfileTabIndex = 4;

class BarberShellController extends GetxController {
  final currentTab = barberDashboardTabIndex.obs;

  // Set by BarberNotificationsController whenever its unread count changes
  // (Get.find<BarberShellController>().unreadNotifications.value = ...) so
  // the Notifications tab's bottom-nav badge stays in sync without the
  // shell needing to know how notifications are fetched.
  final unreadNotifications = 0.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map && args['initialTab'] is int) {
      currentTab.value = args['initialTab'] as int;
    }
  }

  void changeTab(int index) => currentTab.value = index;
}
