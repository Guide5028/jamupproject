// ST-01 — User Login Page Renders
//
// Pumps LoginPage and verifies that the email field, password field,
// and Login button are all present on screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/auth/pages/login_page.dart';

Widget _buildPage() => const MaterialApp(home: LoginPage());

void main() {
  group('ST-01 — User Login Page Renders', () {
    testWidgets('Email field is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget,
          reason: 'Login page must have an Email input field');
    });

    testWidgets('Password field is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget,
          reason: 'Login page must have a Password input field');
    });

    testWidgets('Login button is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget,
          reason: 'Login page must have a Login button');
    });
  });
}
