import 'package:barberia_cuts/app/modules/barber/barber_dashboard_controller.dart';
import 'package:barberia_cuts/app/modules/barber/barber_dashboard_page.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pumpDashboard(
    WidgetTester tester,
    Map<String, ScriptedResponse> script,
  ) async {
    final adapter = ScriptedAdapter(script);
    final storage = FakeStorageService()..token = 'test-token';
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(storage);
    Get.lazyPut<BarberDashboardController>(
      () => BarberDashboardController(),
      fenix: true,
    );

    await tester.pumpWidget(GetMaterialApp(home: const BarberDashboardPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders a loaded day with the next appointment', (
    tester,
  ) async {
    await pumpDashboard(tester, {
      '/v1/staff/day': (
        status: 200,
        body: sampleStaffDayJson(
          nextAppointment: {
            'bookingId': 'b1',
            'clientName': 'Brian Mwangi',
            'services': ['Haircut', 'Beard Trim'],
            'scheduledStart': '2026-07-18T10:30:00.000Z',
            'scheduledEnd': '2026-07-18T11:15:00.000Z',
            'durationMinutes': 45,
            'status': 'booked',
            'channel': 'online',
          },
        ),
      ),
      '/v1/staff/me': (status: 200, body: sampleStaffAccountJson()),
    });

    expect(find.text('James Mwangi'), findsOneWidget);
    expect(find.text('Barber'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Brian Mwangi'), findsOneWidget);
    expect(find.text('Haircut + Beard Trim'), findsOneWidget);
    expect(find.text('Mobile App'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no appointments today', (
    tester,
  ) async {
    await pumpDashboard(tester, {
      '/v1/staff/day': (
        status: 200,
        body: sampleStaffDayJson(
          summary: {'total': 0, 'completed': 0, 'remaining': 0},
        ),
      ),
      '/v1/staff/me': (status: 200, body: sampleStaffAccountJson()),
    });

    expect(find.text('No appointments today.'), findsOneWidget);
    expect(find.text('Enjoy your free time.'), findsOneWidget);
    // The availability card still renders — the barber can still change
    // status on an empty day.
    expect(find.text('Available'), findsOneWidget);
  });

  testWidgets('the status sheet changes presence and confirms against the API', (
    tester,
  ) async {
    await pumpDashboard(tester, {
      '/v1/staff/day': (
        status: 200,
        body: sampleStaffDayJson(presence: 'available'),
      ),
      '/v1/staff/me': (status: 200, body: sampleStaffAccountJson()),
      '/v1/staff/presence': (
        status: 200,
        body: {
          'presence': 'busy',
          'presenceUpdatedAt': '2026-07-18T09:00:00.000Z',
        },
      ),
    });

    expect(find.text('Available'), findsOneWidget);

    await tester.tap(find.text('Change Status'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Busy'));
    await tester.pumpAndSettle();

    expect(find.text('Busy'), findsOneWidget);
    expect(find.text('Available'), findsNothing);
  });
}
