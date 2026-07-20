import 'package:barberia_cuts/app/modules/barber/barber_customer_profile_page.dart';
import 'package:barberia_cuts/app/modules/barber/barber_customers_controller.dart';
import 'package:barberia_cuts/app/modules/barber/barber_customers_page.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pumpCustomers(
    WidgetTester tester,
    Map<String, ScriptedResponse> script,
  ) async {
    final adapter = ScriptedAdapter(script);
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(FakeStorageService()..token = 'test-token');
    Get.put<BarberCustomersController>(BarberCustomersController());

    await tester.pumpWidget(GetMaterialApp(home: const BarberCustomersPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the served-clients list with visit count and last visit', (
    tester,
  ) async {
    await pumpCustomers(tester, {
      'GET /v1/staff/clients': (
        status: 200,
        body: {
          'clients': [
            sampleStaffCustomerJson(
              id: 'client-1',
              name: 'Brian Mwangi',
              visitCount: 4,
            ),
            sampleStaffCustomerJson(
              id: 'client-2',
              name: 'Faith Wanjiru',
              visitCount: 1,
            ),
          ],
        },
      ),
    });

    expect(find.text('Brian Mwangi'), findsOneWidget);
    expect(find.text('4 Visits'), findsOneWidget);
    expect(find.text('Faith Wanjiru'), findsOneWidget);
    expect(find.text('1 Visit'), findsOneWidget);
  });

  testWidgets('shows the empty state when this staff member has served no one', (
    tester,
  ) async {
    await pumpCustomers(tester, {
      'GET /v1/staff/clients': (status: 200, body: {'clients': []}),
    });

    expect(find.text('No customers yet'), findsOneWidget);
  });

  testWidgets('typing a query re-fetches with q after the debounce', (
    tester,
  ) async {
    await pumpCustomers(tester, {
      'GET /v1/staff/clients': (
        status: 200,
        body: {
          'clients': [
            sampleStaffCustomerJson(id: 'client-1', name: 'Brian Mwangi'),
            sampleStaffCustomerJson(id: 'client-2', name: 'Faith Wanjiru'),
          ],
        },
      ),
      'GET /v1/staff/clients?q=Bri': (
        status: 200,
        body: {
          'clients': [
            sampleStaffCustomerJson(id: 'client-1', name: 'Brian Mwangi'),
          ],
        },
      ),
    });

    expect(find.text('Faith Wanjiru'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bri');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Brian Mwangi'), findsOneWidget);
    expect(find.text('Faith Wanjiru'), findsNothing);
  });

  testWidgets('tapping a customer opens their profile with notes and visit timeline', (
    tester,
  ) async {
    await pumpCustomers(tester, {
      'GET /v1/staff/clients': (
        status: 200,
        body: {
          'clients': [
            sampleStaffCustomerJson(id: 'client-1', name: 'Brian Mwangi'),
          ],
        },
      ),
      'GET /v1/staff/clients/client-1': (
        status: 200,
        body: sampleStaffCustomerProfileJson(
          id: 'client-1',
          name: 'Brian Mwangi',
          phone: '0700000001',
        ),
      ),
    });

    await tester.tap(find.text('Brian Mwangi'));
    await tester.pumpAndSettle();

    expect(find.byType(BarberCustomerProfilePage), findsOneWidget);
    expect(find.text('0700000001'), findsOneWidget);
    expect(find.text('Prefers Skin Fade.'), findsOneWidget);
    expect(find.text('Usually books every three weeks.'), findsOneWidget);
    expect(find.text('Haircut + Beard Trim'), findsOneWidget);
  });

  testWidgets('a 403 on the profile shows the not-served message, not a generic error', (
    tester,
  ) async {
    await pumpCustomers(tester, {
      'GET /v1/staff/clients': (
        status: 200,
        body: {
          'clients': [
            sampleStaffCustomerJson(id: 'client-1', name: 'Brian Mwangi'),
          ],
        },
      ),
      'GET /v1/staff/clients/client-1': (
        status: 403,
        body: {'error': 'Forbidden'},
      ),
    });

    await tester.tap(find.text('Brian Mwangi'));
    await tester.pumpAndSettle();

    expect(find.text("Can't view this customer"), findsOneWidget);
    expect(find.text("You haven't served this client yet."), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
