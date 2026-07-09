import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barberia_cuts/app/modules/welcome/welcome_page.dart';

void main() {
  testWidgets('Welcome page renders brand and CTAs', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));

    expect(find.text('Baberia Cuts'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
