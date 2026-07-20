import 'package:barberia_cuts/app/modules/barber/barber_appointment_detail_page.dart';
import 'package:barberia_cuts/app/modules/barber/create_booking/barber_create_booking_controller.dart';
import 'package:barberia_cuts/app/modules/barber/create_booking/pages/customer_page.dart';
import 'package:barberia_cuts/app/routes/app_routes.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  // Same date arithmetic BarberCreateBookingController.nextDates uses —
  // computed here instead of hardcoded so the test stays correct
  // regardless of which day it actually runs on.
  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final todayLabel = DateFormat('EEEE, d MMMM').format(today);

  /// Pumps a barber-shell-shaped route stack (a named barberShell root,
  /// matching how the FAB's Get.until(...barberShell) call finds its way
  /// back) with the wizard's first page pushed on top of it — the same
  /// shape the real FAB tap produces, without needing the full
  /// BarberShellPage's own dependency graph.
  Future<void> pumpWizard(
    WidgetTester tester,
    Map<String, ScriptedResponse> script,
  ) async {
    final adapter = ScriptedAdapter(script);
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(FakeStorageService()..token = 'test-token');
    Get.put<BarberCreateBookingController>(BarberCreateBookingController());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.barberShell,
        getPages: [
          GetPage(
            name: AppRoutes.barberShell,
            page: () => const Scaffold(body: Text('Shell')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    Get.to(() => const CustomerPage());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'happy path: search, pick client, service, date, time, confirm — lands on the new booking detail',
    (tester) async {
      await pumpWizard(tester, {
        'GET /v1/staff/services': (
          status: 200,
          body: {
            'services': [sampleStaffServiceJson(id: 'svc-1', name: 'Haircut')],
          },
        ),
        'GET /v1/staff/clients/search?q=Bri': (
          status: 200,
          body: {
            'clients': [
              sampleStaffClientJson(
                id: 'client-1',
                name: 'Brian Mwangi',
                phone: '0700000001',
              ),
            ],
          },
        ),
        'GET /v1/staff/availability?date=$todayStr&service=svc-1': (
          status: 200,
          body: {
            'date': todayStr,
            'slots': [
              sampleStaffSlotJson(
                start: '${todayStr}T09:00:00.000Z',
                end: '${todayStr}T09:45:00.000Z',
                label: '9:00 AM',
              ),
            ],
          },
        ),
        'POST /v1/staff/bookings': (
          status: 201,
          body: {
            'booking': {'id': 'booking-99', 'status': 'booked'},
          },
        ),
        'GET /v1/staff/bookings/booking-99': (
          status: 200,
          body: sampleBookingDetailJson(
            bookingId: 'booking-99',
            clientName: 'Brian Mwangi',
          ),
        ),
      });

      // Step 1: customer — search, then pick the match.
      await tester.enterText(find.byType(TextField).first, 'Bri');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Brian Mwangi'), findsOneWidget);
      await tester.tap(find.text('Brian Mwangi'));
      await tester.pumpAndSettle();

      // Step 2: service.
      expect(find.text('Haircut'), findsOneWidget);
      await tester.tap(find.text('Haircut'));
      await tester.pumpAndSettle();

      // Step 3: date.
      expect(find.text(todayLabel), findsOneWidget);
      await tester.tap(find.text(todayLabel));
      await tester.pumpAndSettle();

      // Step 4: time.
      expect(find.text('9:00 AM'), findsOneWidget);
      await tester.tap(find.text('9:00 AM'));
      await tester.pumpAndSettle();

      // Step 5: review — confirm.
      expect(find.text('Confirm booking'), findsOneWidget);
      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      // No dedicated "Booked!" screen — straight to the new booking's own
      // detail page.
      expect(find.byType(BarberAppointmentDetailPage), findsOneWidget);
      expect(find.text('Brian Mwangi'), findsWidgets);
    },
  );

  testWidgets(
    'a phone_taken 409 registering a new client keeps the form open with the specific error',
    (tester) async {
      await pumpWizard(tester, {
        'GET /v1/staff/services': (
          status: 200,
          body: {'services': []},
        ),
        'GET /v1/staff/clients/search?q=Faith': (
          status: 200,
          body: {'clients': []},
        ),
        'POST /v1/staff/clients': (
          status: 409,
          body: {
            'error': 'phone_taken',
            'message': 'A client with this phone number already exists.',
          },
        ),
      });

      // No matches — the "register a new client" form only surfaces below
      // a completed (empty) search, same as the real "call in, not found
      // yet, sign them up" flow.
      await tester.enterText(find.byType(TextField).first, 'Faith');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Faith');
      await tester.enterText(
        find.widgetWithText(TextField, 'Phone number'),
        '0711111111',
      );
      await tester.tap(find.text('Register and continue'));
      await tester.pumpAndSettle();

      expect(
        find.text('A client with this phone number already exists.'),
        findsOneWidget,
      );
      // Still on the customer step — the form didn't advance.
      expect(find.byType(CustomerPage), findsOneWidget);
    },
  );

  testWidgets(
    'a slot_taken 409 on submit surfaces retry slots inline on the review page',
    (tester) async {
      await pumpWizard(tester, {
        'GET /v1/staff/services': (
          status: 200,
          body: {
            'services': [sampleStaffServiceJson(id: 'svc-1', name: 'Haircut')],
          },
        ),
        'GET /v1/staff/clients/search?q=Bri': (
          status: 200,
          body: {
            'clients': [
              sampleStaffClientJson(id: 'client-1', name: 'Brian Mwangi'),
            ],
          },
        ),
        'GET /v1/staff/availability?date=$todayStr&service=svc-1': (
          status: 200,
          body: {
            'date': todayStr,
            'slots': [
              sampleStaffSlotJson(
                start: '${todayStr}T09:00:00.000Z',
                end: '${todayStr}T09:45:00.000Z',
                label: '9:00 AM',
              ),
            ],
          },
        ),
        'POST /v1/staff/bookings': (
          status: 409,
          body: {
            'error': 'slot_taken',
            'message': 'That slot is no longer available. Here are the next open slots.',
            'slots': [
              sampleStaffSlotJson(
                start: '${todayStr}T10:00:00.000Z',
                end: '${todayStr}T10:45:00.000Z',
                label: '10:00 AM',
              ),
            ],
          },
        ),
      });

      await tester.enterText(find.byType(TextField).first, 'Bri');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brian Mwangi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Haircut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(todayLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.text('9:00 AM'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm booking'));
      await tester.pumpAndSettle();

      expect(
        find.text('That slot is no longer available. Here are the next open slots.'),
        findsOneWidget,
      );
      expect(find.text('10:00 AM'), findsOneWidget);
      // Still on the review page — a slot conflict doesn't kick the barber
      // back to an earlier step.
      expect(find.text('Confirm booking'), findsOneWidget);
    },
  );
}
