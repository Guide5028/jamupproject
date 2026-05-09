// ST-18 — Gig Detail Page Displays Description
//
// Pumps GigDetailPage with a fake Gig that has a description and verifies
// that the description text is visible after scrolling to the About section.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/models/gig.dart';
import 'package:jamup_app/features/gigs/pages/gig_detail_page.dart';

Gig _fakeGig() => Gig(
      id: 'g3',
      title: 'Electric Nights',
      description: 'An electrifying night of EDM and live performance.',
      location: 'Pattaya',
      date: DateTime(2026, 12, 31, 22, 0),
      imageUrl: '',
      genres: const ['EDM'],
      venueId: 'v1',
      musicianId: '',
      latitude: 12.9,
      longitude: 100.8,
      roleNeeded: 'DJ',
      payment: 5000,
    );

Widget _buildPage() => MaterialApp(home: GigDetailPage(gig: _fakeGig()));

void main() {
  group('ST-18 — Gig Detail Page Displays Description', () {
    testWidgets('Description text is visible after scrolling', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      await tester.scrollUntilVisible(
          find.textContaining('electrifying'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.textContaining('electrifying'), findsOneWidget,
          reason: 'Gig detail page must display the description text');
    });

    testWidgets('Payment info is visible after scrolling', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      // Payment label "5,000 THB" or similar
      await tester.scrollUntilVisible(
          find.textContaining('5'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.textContaining('5'), findsWidgets,
          reason: 'Gig detail page must display the payment information');
    });

    testWidgets('Genre tag is visible on the gig detail page', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('EDM'), findsWidgets,
          reason: 'Gig detail page must display the genre tag');
    });
  });
}
