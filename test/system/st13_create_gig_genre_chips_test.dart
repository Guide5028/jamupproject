// ST-13 — Create Gig Genre Chips Are Selectable
//
// Pumps CreateGigPage, scrolls to the Genres section, and verifies that
// genre FilterChips are rendered and can be tapped to select a genre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/gigs/pages/create_gig_page.dart';

void main() {
  group('ST-13 — Create Gig Genre Chips Are Selectable', () {
    testWidgets('Jazz genre chip is visible after scrolling', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: CreateGigPage()));
      await tester.pump();

      await tester.scrollUntilVisible(
          find.widgetWithText(FilterChip, 'Jazz'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.widgetWithText(FilterChip, 'Jazz'), findsOneWidget,
          reason: 'Create Gig form must display genre chips');
    });

    testWidgets('Tapping Jazz chip selects it', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: CreateGigPage()));
      await tester.pump();

      await tester.scrollUntilVisible(
          find.widgetWithText(FilterChip, 'Jazz'), 200,
          scrollable: find.byType(Scrollable).first);

      final jazzChip = find.widgetWithText(FilterChip, 'Jazz');
      await tester.tap(jazzChip);
      await tester.pump();

      final chip = tester.widget<FilterChip>(jazzChip);
      expect(chip.selected, isTrue,
          reason: 'Tapping a genre chip must select it');
    });

    testWidgets('Multiple genre chips are rendered', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: CreateGigPage()));
      await tester.pump();

      await tester.scrollUntilVisible(
          find.widgetWithText(FilterChip, 'Rock'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.byType(FilterChip), findsWidgets,
          reason: 'Create Gig form must display multiple genre chips');
    });
  });
}
