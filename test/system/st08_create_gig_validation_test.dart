// ST-08 — Create Gig Validates Required Title
//
// Pumps CreateGigPage, scrolls to the "Create Gig" button, taps it
// without filling the Title field, and verifies the validation error.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/gigs/pages/create_gig_page.dart';

final _saveBtn = find.widgetWithText(ElevatedButton, 'Create Gig');

Future<void> _scrollToSave(WidgetTester tester) =>
    tester.scrollUntilVisible(_saveBtn, 200,
        scrollable: find.byType(Scrollable).first);

void main() {
  group('ST-08 — Create Gig Validates Required Title', () {
    testWidgets('Tapping Create Gig with empty title shows validation error',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: CreateGigPage()));
      await tester.pump();

      await _scrollToSave(tester);
      await tester.tap(_saveBtn);
      await tester.pump();

      expect(find.text('Title required'), findsOneWidget,
          reason: 'Empty title must trigger a validation error');
    });

    testWidgets('Valid title entered does not trigger title error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: CreateGigPage()));
      await tester.pump();

      // Fill in the title first
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'My New Gig');
      await tester.pump();

      // Tap save — no title error because title is filled
      await _scrollToSave(tester);
      await tester.tap(_saveBtn);
      await tester.pump();

      expect(find.text('Title required'), findsNothing,
          reason: 'A filled title must not show a validation error');
    });
  });
}
