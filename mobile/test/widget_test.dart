import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barberia_cuts/app/modules/welcome/welcome_page.dart';

void main() {
  testWidgets('Welcome splash renders the brand and pulses the logo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeSplashContent()));

    expect(find.text('Baberia Cuts'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Advance partway through the pulse loop to confirm the animation
    // drives without error. Deliberately not pumpAndSettle() — the pulse
    // repeats forever, so that would hang.
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.takeException(), isNull);
  });
}
