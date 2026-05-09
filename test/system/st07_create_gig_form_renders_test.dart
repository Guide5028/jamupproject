// ST-07 — Create Gig Form Renders
//
// Pumps CreateGigPage and verifies that the essential form fields
// (Title, Description, Role selector) are present.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/gigs/pages/create_gig_page.dart';

Widget _buildPage() => const MaterialApp(home: CreateGigPage());

void main() {
  group('ST-07 — Create Gig Form Renders', () {
    testWidgets('Title field is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Title'), findsOneWidget,
          reason: 'Create Gig form must have a Title field');
    });

    testWidgets('Description field is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget,
          reason: 'Create Gig form must have a Description field');
    });

    testWidgets('Role selector dropdown is present after scrolling',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildPage());
      await tester.pump();

      // The role dropdown is in the Details section — scroll to reveal it.
      await tester.scrollUntilVisible(
          find.byType(DropdownButtonFormField<String>).first, 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.byType(DropdownButtonFormField<String>), findsWidgets,
          reason: 'Create Gig form must have a Role dropdown');
    });
  });
}
