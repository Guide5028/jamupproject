// ST-21 — Edit Profile Page Form Renders
//
// Pumps EditProfilePage and verifies that the Name/Venue and Bio text
// fields and the Save Changes button are rendered.
// _loadProfile() fails gracefully (no Supabase) so _loading becomes false
// and the form is visible.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/profile/pages/edit_profile_page.dart';

Widget _buildPage() => const MaterialApp(home: EditProfilePage());

void main() {
  group('ST-21 — Edit Profile Page Form Renders', () {
    testWidgets('Name / Venue field is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      // pumpAndSettle lets _loadProfile() fail and _loading flip to false,
      // so the form body becomes visible.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextFormField, 'Name / Venue'), findsOneWidget,
          reason: 'Edit Profile must show a Name/Venue input field');
    });

    testWidgets('Bio field is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.widgetWithText(TextFormField, 'Bio'), findsOneWidget,
          reason: 'Edit Profile must show a Bio input field');
    });

    testWidgets('Save Changes button is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.scrollUntilVisible(
          find.widgetWithText(ElevatedButton, 'Save Changes'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget,
          reason: 'Edit Profile must have a Save Changes button');
    });
  });
}
