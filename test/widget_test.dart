import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:her_health_app/screens/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen displays the Her Health introduction',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.text('Her Health'), findsOneWidget);
    expect(find.text('Your wellness journey starts here'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
