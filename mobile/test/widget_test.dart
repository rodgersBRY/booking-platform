import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barberia_cuts/app/modules/welcome/welcome_page.dart';

void main() {
  testWidgets('Welcome splash renders the brand', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeSplashContent()));

    expect(find.text('Baberia Cuts'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
