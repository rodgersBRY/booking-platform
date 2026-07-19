import 'package:barberia_cuts/app/modules/barber/barber_appointment_detail_page.dart';
import 'package:barberia_cuts/app/modules/barber/barber_notifications_controller.dart';
import 'package:barberia_cuts/app/modules/barber/barber_notifications_page.dart';
import 'package:barberia_cuts/app/services/api_service.dart';
import 'package:barberia_cuts/app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/fake_services.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<ScriptedAdapter> pumpNotifications(
    WidgetTester tester,
    Map<String, ScriptedResponse> script,
  ) async {
    final adapter = ScriptedAdapter(script);
    Get.put<ApiService>(FakeApiService(adapter));
    Get.put<StorageService>(FakeStorageService()..token = 'test-token');
    Get.put<BarberNotificationsController>(BarberNotificationsController());

    await tester.pumpWidget(
      GetMaterialApp(home: const BarberNotificationsPage()),
    );
    await tester.pumpAndSettle();
    return adapter;
  }

  /// The unread indicator is a small circular dot Container, rendered only
  /// on unread tiles (see _NotificationTile in barber_notifications_page.dart)
  /// — distinct from every other Container in the tile, none of which use
  /// BoxShape.circle.
  int unreadDotCount(WidgetTester tester) {
    return tester
        .widgetList<Container>(find.byType(Container))
        .where((container) {
          final decoration = container.decoration;
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle;
        })
        .length;
  }

  testWidgets(
    'renders notifications with unread ones visually distinguished from read ones',
    (tester) async {
      await pumpNotifications(tester, {
        'GET /v1/staff/notifications': (
          status: 200,
          body: sampleStaffNotificationsJson(
            notifications: [
              sampleStaffNotificationJson(
                id: 'n1',
                title: 'Booking Confirmed',
                bookingId: null,
              ),
              sampleStaffNotificationJson(
                id: 'n2',
                title: 'Booking Cancelled',
                bookingId: null,
                readAt: '2026-07-19T07:00:00.000Z',
              ),
            ],
          ),
        ),
      });

      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.text('Booking Cancelled'), findsOneWidget);

      final unreadTitle = tester.widget<Text>(find.text('Booking Confirmed'));
      final readTitle = tester.widget<Text>(find.text('Booking Cancelled'));
      expect(unreadTitle.style?.fontWeight, FontWeight.w700);
      expect(readTitle.style?.fontWeight, FontWeight.w600);

      // Exactly one unread dot — for the one unread entry.
      expect(unreadDotCount(tester), 1);
    },
  );

  testWidgets(
    'tapping an unread notification marks it read against the API and locally',
    (tester) async {
      final adapter = await pumpNotifications(tester, {
        'GET /v1/staff/notifications': (
          status: 200,
          body: sampleStaffNotificationsJson(
            notifications: [
              sampleStaffNotificationJson(
                id: 'n1',
                title: 'Booking Confirmed',
                bookingId: null,
              ),
            ],
          ),
        ),
        'POST /v1/staff/notifications/read': (status: 200, body: {}),
      });

      expect(unreadDotCount(tester), 1);
      var title = tester.widget<Text>(find.text('Booking Confirmed'));
      expect(title.style?.fontWeight, FontWeight.w700);

      await tester.tap(find.text('Booking Confirmed'));
      await tester.pumpAndSettle();

      expect(
        adapter.requestedPaths,
        contains('/v1/staff/notifications/read'),
      );
      expect(adapter.requestedBodies.last, {'id': 'n1'});

      title = tester.widget<Text>(find.text('Booking Confirmed'));
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(unreadDotCount(tester), 0);
    },
  );

  testWidgets(
    'Mark all read clears every unread entry with a single all:true request',
    (tester) async {
      final adapter = await pumpNotifications(tester, {
        'GET /v1/staff/notifications': (
          status: 200,
          body: sampleStaffNotificationsJson(
            notifications: [
              sampleStaffNotificationJson(
                id: 'n1',
                title: 'Booking Confirmed',
                bookingId: null,
              ),
              sampleStaffNotificationJson(
                id: 'n2',
                title: 'Booking Cancelled',
                bookingId: null,
              ),
            ],
          ),
        ),
        'POST /v1/staff/notifications/read': (status: 200, body: {}),
      });

      expect(find.text('Mark all read'), findsOneWidget);
      expect(unreadDotCount(tester), 2);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(adapter.requestedBodies.last, {'all': true});

      final firstTitle = tester.widget<Text>(find.text('Booking Confirmed'));
      final secondTitle = tester.widget<Text>(find.text('Booking Cancelled'));
      expect(firstTitle.style?.fontWeight, FontWeight.w600);
      expect(secondTitle.style?.fontWeight, FontWeight.w600);
      expect(unreadDotCount(tester), 0);

      // Nothing left unread — the button hides itself.
      expect(find.text('Mark all read'), findsNothing);
    },
  );

  testWidgets("shows the empty state when there are no notifications", (
    tester,
  ) async {
    await pumpNotifications(tester, {
      'GET /v1/staff/notifications': (
        status: 200,
        body: sampleStaffNotificationsJson(notifications: []),
      ),
    });

    expect(find.text("You're all caught up."), findsOneWidget);
  });

  testWidgets(
    'tapping a notification with a bookingId opens its appointment detail',
    (tester) async {
      await pumpNotifications(tester, {
        'GET /v1/staff/notifications': (
          status: 200,
          body: sampleStaffNotificationsJson(
            notifications: [
              sampleStaffNotificationJson(
                id: 'n1',
                title: 'Booking Confirmed',
                bookingId: 'b1',
              ),
            ],
          ),
        ),
        'GET /v1/staff/bookings/b1': (
          status: 200,
          body: sampleBookingDetailJson(bookingId: 'b1', clientName: 'Brian Mwangi'),
        ),
      });

      await tester.tap(find.text('Booking Confirmed'));
      await tester.pumpAndSettle();

      expect(find.byType(BarberAppointmentDetailPage), findsOneWidget);
      expect(find.text('Brian Mwangi'), findsWidgets);
    },
  );
}
