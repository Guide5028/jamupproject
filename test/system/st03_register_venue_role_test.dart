// ST-03 — Register with Venue Role
//
// Pumps RegisterPage and verifies that the role dropdown defaults to
// "musician" and that the user can switch it to "venue".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/auth/pages/register_page.dart';

Widget _buildPage() => const MaterialApp(home: RegisterPage());

void main() {
  group('ST-03 — Register with Venue Role', () {
    testWidgets('Register page renders role dropdown', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsWidgets,
          reason: 'Register page must contain a role dropdown');
    });

    testWidgets('Role dropdown defaults to Musician', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      // The dropdown item label for the default role is "Musician" (capitalised).
      expect(find.text('Musician'), findsOneWidget,
          reason: 'Default role must be Musician');
    });

    testWidgets('Role dropdown can switch to Venue', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      // Tap the Venue option (last instance to pick the menu item)
      await tester.tap(find.text('Venue').last);
      await tester.pumpAndSettle();

      expect(find.text('Venue'), findsOneWidget,
          reason: 'Role dropdown must allow selecting Venue');
    });
  });
}
