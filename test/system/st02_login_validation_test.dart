// ST-02 — Login Form Validation
//
// Pumps LoginPage and taps Login with empty fields.
// Verifies that validation error messages appear without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/auth/pages/login_page.dart';

Widget _buildPage() => const MaterialApp(home: LoginPage());

void main() {
  group('ST-02 — Login Form Validation', () {
    testWidgets('Empty email shows validation error', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      // Tap Login without entering any data
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.textContaining('email'), findsWidgets,
          reason: 'Empty email must trigger a validation error');
    });

    testWidgets('Entering email and leaving password empty shows error',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'user@test.com');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.textContaining('assword'), findsWidgets,
          reason: 'Empty password must trigger a validation error');
    });
  });
}
