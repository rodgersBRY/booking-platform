import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barberia_cuts/app/modules/home/home_binding.dart';
import 'package:barberia_cuts/app/modules/home/home_page.dart';

void main() {
  testWidgets('Home page renders title', (WidgetTester tester) async {
    HomeBinding().dependencies();
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('Barberia Cuts'), findsOneWidget);
  });
}
