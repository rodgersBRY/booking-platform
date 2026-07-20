import 'package:barberia_cuts/app/modules/barber/barber_appointment_detail_controller.dart';
import 'package:barberia_cuts/app/modules/barber/barber_appointment_detail_page.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pumpDetail(
    WidgetTester tester,
    Map<String, ScriptedResponse> script, {
    String bookingId = 'b1',
  }) async {
    // The detail page is a long ListView (customer/appointment/services/
    // notes cards plus the primary action button below them) — the
    // default 800x600 test surface clips the primary action out of the
    // tree entirely (ListView only builds children in/near the
    // viewport), so widen it to fit everything without scrolling.
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = ScriptedAdapter(script);
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(FakeStorageService()..token = 'test-token');

    await tester.pumpWidget(
      GetMaterialApp(home: BarberAppointmentDetailPage(bookingId: bookingId)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders customer info, appointment info, services, notes, and status', (
    tester,
  ) async {
    await pumpDetail(tester, {
      'GET /v1/staff/bookings/b1': (
        status: 200,
        body: sampleBookingDetailJson(),
      ),
    });

    expect(find.text('Brian Mwangi'), findsWidgets);
    expect(find.text('0700000000'), findsOneWidget);
    expect(find.text('14 previous visits'), findsOneWidget);
    expect(find.text('Haircut'), findsOneWidget);
    expect(find.text('Beard Trim'), findsOneWidget);
    expect(find.text('Prefers Skin Fade.'), findsOneWidget);
    expect(find.text('Usually books every three weeks.'), findsOneWidget);
    expect(find.text('Start Service'), findsOneWidget);
  });

  testWidgets('Start Service calls startBooking and updates on success', (
    tester,
  ) async {
    await pumpDetail(tester, {
      'GET /v1/staff/bookings/b1': (
        status: 200,
        body: sampleBookingDetailJson(canStart: true, canComplete: false),
      ),
      'POST /v1/staff/bookings/b1/start': (
        status: 200,
        body: {
          'booking': sampleBookingDetailJson(
            status: 'in_chair',
            canStart: false,
            canComplete: true,
          ),
        },
      ),
    });

    expect(find.text('Start Service'), findsOneWidget);

    await tester.tap(find.text('Start Service'));
    await tester.pumpAndSettle();

    expect(find.text('Complete Service'), findsOneWidget);
    expect(find.text('Start Service'), findsNothing);
  });

  testWidgets('a staff_busy 409 on start surfaces the specific message with a retry action', (
    tester,
  ) async {
    await pumpDetail(tester, {
      'GET /v1/staff/bookings/b1': (
        status: 200,
        body: sampleBookingDetailJson(canStart: true, canComplete: false),
      ),
      'POST /v1/staff/bookings/b1/start': (
        status: 409,
        body: {
          'error': 'staff_busy',
          'message': 'That barber is busy right now.',
        },
      ),
    });

    await tester.tap(find.text('Start Service'));
    await tester.pumpAndSettle();

    expect(find.text('That barber is busy right now.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    final controller = Get.find<BarberAppointmentDetailController>(tag: 'b1');
    expect(controller.staffBusy.value, isTrue);
    // Still startable — the conflict didn't change the booking's state.
    expect(find.text('Start Service'), findsOneWidget);
  });

  testWidgets('a generic failure on start surfaces the message without a retry action', (
    tester,
  ) async {
    await pumpDetail(tester, {
      'GET /v1/staff/bookings/b1': (
        status: 200,
        body: sampleBookingDetailJson(canStart: true, canComplete: false),
      ),
      'POST /v1/staff/bookings/b1/start': (
        status: 500,
        body: {'error': 'server_error', 'message': 'Something broke.'},
      ),
    });

    await tester.tap(find.text('Start Service'));
    await tester.pumpAndSettle();

    expect(find.text('Something broke.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    final controller = Get.find<BarberAppointmentDetailController>(tag: 'b1');
    expect(controller.staffBusy.value, isFalse);
  });

  testWidgets('Complete Service prompts for notes then calls completeBooking', (
    tester,
  ) async {
    await pumpDetail(tester, {
      'GET /v1/staff/bookings/b1': (
        status: 200,
        body: sampleBookingDetailJson(
          status: 'in_chair',
          canStart: false,
          canComplete: true,
        ),
      ),
      'POST /v1/staff/bookings/b1/complete': (
        status: 200,
        body: {'visit': {}},
      ),
    });

    expect(find.text('Complete Service'), findsOneWidget);

    await tester.tap(find.text('Complete Service'));
    await tester.pumpAndSettle();

    // The service-notes bottom sheet is open with its own confirm button.
    expect(find.text('Add Service Notes'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Used a #2 guard');

    await tester.tap(find.byKey(const Key('confirmCompleteServiceButton')));
    await tester.pumpAndSettle();

    // No primary action left once completed.
    expect(find.text('Start Service'), findsNothing);
    expect(find.text('Complete Service'), findsNothing);
  });
}
