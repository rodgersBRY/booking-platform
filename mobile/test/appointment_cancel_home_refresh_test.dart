import 'package:barberia_cuts/app/modules/appointments/appointment_detail_page.dart';
import 'package:barberia_cuts/app/modules/appointments/models/booking_model.dart';
import 'package:barberia_cuts/app/modules/home/home_controller.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

/// Regression test for a bug where cancelling an appointment left the Home
/// tab's "upcoming appointment" card showing the just-cancelled booking.
/// Home and Appointments are both kept alive by ShellPage's IndexedStack, so
/// HomeController.load() only ever runs once unless something explicitly
/// re-triggers it — cancelling from the appointment detail page refreshed
/// AppointmentsController but never told HomeController to refresh too.
void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Map<String, dynamic> bookingJson() => {
    'id': 'b1',
    'status': 'booked',
    'channel': 'online',
    'scheduledStart': '2026-07-20T10:30:00.000Z',
    'scheduledEnd': '2026-07-20T11:15:00.000Z',
    'service': {
      'id': 'svc1',
      'name': 'Haircut',
      'category': null,
      'durationMinutes': 45,
      'price': 800,
    },
    'staff': {'id': 'st1', 'name': 'James', 'role': 'barber', 'avatarUrl': null},
    'canCancel': true,
    'canReschedule': false,
  };

  testWidgets(
    "cancelling an appointment refreshes Home's upcoming booking",
    (tester) async {
      final adapter = ScriptedAdapter({
        '/v1/public/services': (status: 200, body: {'services': []}),
        '/v1/public/barbers': (status: 200, body: {'barbers': []}),
        '/v1/account/me': (
          status: 200,
          body: {
            'client': {
              'id': 'c1',
              'name': 'Brian',
              'phone': '0700000000',
              'email': null,
              'loyaltyPoints': 0,
              'totalVisits': 1,
            },
          },
        ),
        '/v1/account/bookings': (
          status: 200,
          body: {'upcoming': [bookingJson()], 'completed': [], 'cancelled': []},
        ),
        '/v1/account/notifications': (
          status: 200,
          body: {'notifications': [], 'unreadCount': 0},
        ),
        '/v1/account/bookings/b1/cancel': (status: 200, body: {}),
      });

      Get.put<ApiService>(FakeApiService(adapter));
      Get.put<StorageService>(FakeStorageService()..token = 'test-token');
      Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

      // Simulates the Home tab having already been visited once, the way
      // ShellPage's IndexedStack keeps it alive (and its controller loaded)
      // for the whole session.
      Get.find<HomeController>();
      await tester.pumpAndSettle();
      final bookingsCallsBeforeCancel = adapter.requestedPaths
          .where((p) => p == '/v1/account/bookings')
          .length;
      expect(bookingsCallsBeforeCancel, 1);

      await tester.pumpWidget(
        GetMaterialApp(
          home: AppointmentDetailPage(
            booking: BookingModel.fromJson(bookingJson()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel appointment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel it'));
      await tester.pumpAndSettle();
      // Get.snackbar schedules a real (non-Ticker) delay Timer for its
      // auto-dismiss, so pumpAndSettle's "no frame scheduled" check
      // considers things settled before that Timer ever fires. Advance
      // past it explicitly, then let the resulting dismiss animation's
      // own Ticker finish and dispose before the test tears the tree down.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final bookingsCallsAfterCancel = adapter.requestedPaths
          .where((p) => p == '/v1/account/bookings')
          .length;
      expect(
        bookingsCallsAfterCancel,
        bookingsCallsBeforeCancel + 1,
        reason:
            'HomeController.load() should be re-triggered after a successful '
            'cancel so the upcoming-appointment card drops the cancelled '
            'booking instead of showing stale data.',
      );
    },
  );
}
