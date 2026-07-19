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
    
    Get.put<ApiService>(
      FakeApiService(
        ScriptedAdapter({
          '/v1/staff/day': (status: 200, body: sampleStaffDayJson()),
        }),
      ),
    );
    Get.put<StorageService>(FakeStorageService());
  });

  tearDown(Get.reset);

  testWidgets('bottom nav switches the visible barber tab', (tester) async {
    BarberShellBinding().dependencies();
    final controller = Get.find<BarberShellController>();

    await tester.pumpWidget(GetMaterialApp(home: const BarberShellPage()));
    // Dashboard's initial load() (and, later, its tab-focus refresh) fire
    // a real async Dio call against the fake adapter — pumpAndSettle
    // flushes it instead of leaving a Dio-internal timer pending past the
    // end of the test. Safe here because the resulting shimmer/skeleton
    // is only mounted for the instant it takes the fake adapter to
    // resolve, so it doesn't spin forever the way a bare pump() sequence
    // would need to race it.
    await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();
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
