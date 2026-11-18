import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_portal/screens/login_screen.dart';

void main() {
  testWidgets('Admin login screen displays its login interface',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Admin portal'), findsOneWidget);
    expect(find.text('Log in'), findsNWidgets(2));
    expect(
      find.widgetWithText(ElevatedButton, 'Log in'),
      findsOneWidget,
    );
    expect(find.text('For practice staff only.'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}

