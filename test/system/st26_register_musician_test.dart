// ST-26 — Register New Account (Musician Role)
//
// Pumps the RegisterPage with a fake AuthService and verifies that the form
// renders all required fields, validates empty inputs, and calls signUp with
// the correct role when valid data is submitted.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jamup_app/features/auth/pages/register_page.dart';
import 'package:jamup_app/core/services/auth_service.dart';

// ── Fake auth service ──────────────────────────────────────────────────────

class _FakeAuthService extends AuthService {
  Map<String, String>? lastSignUp;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    lastSignUp = {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    };
    // Return an empty AuthResponse — no session needed for the test.
    return AuthResponse();
  }
}

// ── Test ───────────────────────────────────────────────────────────────────

void main() {
  group('ST-26 — Register New Account (Musician Role)', () {
    testWidgets('Register page renders all required fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    });

    testWidgets('Role dropdown defaults to Musician', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );
      await tester.pump();

      // The dropdown should show "Musician" as the selected value by default.
      expect(find.text('Musician'), findsOneWidget);
    });

    testWidgets('Empty form submission shows validation errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget,
          reason: 'Name validation error must appear when name is empty');
      expect(find.text('Please enter your email'), findsOneWidget,
          reason: 'Email validation error must appear when email is empty');
    });

    testWidgets('Invalid email shows email format error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Test User');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'pass123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Short password shows minimum length error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Test User');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();

      expect(find.text('Minimum 6 characters'), findsOneWidget);
    });

    testWidgets('Valid musician registration calls signUp with role=musician',
        (tester) async {
      final fakeAuth = _FakeAuthService();

      await tester.pumpWidget(
        MaterialApp(home: RegisterPage(auth: fakeAuth)),
      );
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Test Musician');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@musician.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'testpass123');

      // Role is already "Musician" by default — no dropdown change needed.

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump(const Duration(seconds: 1));

      expect(fakeAuth.lastSignUp, isNotNull,
          reason: 'signUp must be called when form is valid');
      expect(fakeAuth.lastSignUp!['name'], 'Test Musician');
      expect(fakeAuth.lastSignUp!['email'], 'test@musician.com');
      expect(fakeAuth.lastSignUp!['role'], 'musician');
    });
  });
}
