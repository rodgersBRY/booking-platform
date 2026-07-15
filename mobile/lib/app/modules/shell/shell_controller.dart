import 'package:get/get.dart';

/// Tab indices, kept as constants so other controllers can request a tab
/// (e.g. jumping to Appointments right after a booking confirms) without
/// magic numbers.
const homeTabIndex = 0;
const bookTabIndex = 1;
const appointmentsTabIndex = 2;
const exploreTabIndex = 3;
const profileTabIndex = 4;

class ShellController extends GetxController {
  final currentTab = homeTabIndex.obs;

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
