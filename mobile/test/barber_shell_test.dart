import 'package:barberia_cuts/app/modules/barber/barber_shell_binding.dart';
import 'package:barberia_cuts/app/modules/barber/barber_shell_controller.dart';
import 'package:barberia_cuts/app/modules/barber/barber_shell_page.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:barberia_cuts/app/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    // The Profile tab is a real GetView, so IndexedStack building it
    // eagerly (it builds every tab, not just the visible one) resolves
    // BarberProfileController, which reaches for these. No token means
    // fetchMe() short-circuits before touching the adapter.
    Get.put<ApiService>(FakeApiService(NoRequestsExpectedAdapter()));
    Get.put<StorageService>(FakeStorageService());
  });

  tearDown(Get.reset);

  testWidgets('bottom nav switches the visible barber tab', (tester) async {
    BarberShellBinding().dependencies();
    final controller = Get.find<BarberShellController>();

    await tester.pumpWidget(GetMaterialApp(home: const BarberShellPage()));
    await tester.pump();

    expect(controller.currentTab.value, barberDashboardTabIndex);
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      barberDashboardTabIndex,
    );

    Future<void> tapTab(String label, int expectedIndex) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNavBar),
          matching: find.text(label),
        ),
      );
      await tester.pump();
      expect(controller.currentTab.value, expectedIndex);
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        expectedIndex,
      );
    }

    await tapTab('Schedule', barberScheduleTabIndex);
    await tapTab('Customers', barberCustomersTabIndex);
    await tapTab('Notifications', barberNotificationsTabIndex);
    await tapTab('Profile', barberProfileTabIndex);
    await tapTab('Dashboard', barberDashboardTabIndex);
  });
}
