import 'package:barberia_cuts/app/modules/barber/barber_schedule_controller.dart';
import 'package:barberia_cuts/app/modules/barber/barber_schedule_page.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pumpSchedule(
    WidgetTester tester,
    Map<String, ScriptedResponse> script,
  ) async {
    final adapter = ScriptedAdapter(script);
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(FakeStorageService()..token = 'test-token');
    Get.put<BarberScheduleController>(BarberScheduleController());

    await tester.pumpWidget(GetMaterialApp(home: const BarberSchedulePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders appointments for the active range and switches on tab tap', (
    tester,
  ) async {
    await pumpSchedule(tester, {
      'GET /v1/staff/schedule?range=today': (
        status: 200,
        body: sampleScheduleJson(
          range: 'today',
          schedule: [
            sampleScheduleEntryJson(bookingId: 't1', clientName: 'Brian Mwangi'),
          ],
        ),
      ),
      'GET /v1/staff/schedule?range=tomorrow': (
        status: 200,
        body: sampleScheduleJson(
          range: 'tomorrow',
          schedule: [
            sampleScheduleEntryJson(
              bookingId: 'tm1',
              clientName: 'Faith Wanjiru',
              scheduledStart: '2026-07-19T09:00:00.000Z',
              scheduledEnd: '2026-07-19T09:45:00.000Z',
            ),
          ],
        ),
      ),
    });

    expect(find.text('Brian Mwangi'), findsOneWidget);
    expect(find.text('Faith Wanjiru'), findsNothing);

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    expect(find.text('Faith Wanjiru'), findsOneWidget);
    expect(find.text('Brian Mwangi'), findsNothing);
  });

  testWidgets('shows the empty state when a range has no appointments', (
    tester,
  ) async {
    await pumpSchedule(tester, {
      'GET /v1/staff/schedule?range=today': (
        status: 200,
        body: sampleScheduleJson(range: 'today', schedule: []),
      ),
    });

    expect(find.text('No appointments today.'), findsOneWidget);
    expect(find.text('Enjoy your free time.'), findsOneWidget);
  });
}
