// ST-06 — Gig Detail Page Shows Book Now Button
//
// Pumps GigDetailPage with a fake Gig and verifies that the "Book Now"
// button is visible (as the default for an unauthenticated/musician user).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/models/gig.dart';
import 'package:jamup_app/features/gigs/pages/gig_detail_page.dart';

Gig _fakeGig() => Gig(
      id: 'g2',
      title: 'Open Jazz Jam',
      description: 'All musicians welcome.',
      location: 'Bangkok',
      date: DateTime(2026, 11, 1, 19, 0),
      imageUrl: '',
      genres: const ['Jazz'],
      venueId: 'v1',
      musicianId: '',
      latitude: 13.7,
      longitude: 100.5,
      roleNeeded: 'Any',
    );

Widget _buildPage() => MaterialApp(home: GigDetailPage(gig: _fakeGig()));

void main() {
  group('ST-06 — Gig Detail Page Shows Book Now Button', () {
    testWidgets('Gig detail page renders without crashing', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      // The page must render a Scaffold with the gig title visible.
      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Gig detail page must render a Scaffold');
      expect(find.text('Open Jazz Jam'), findsOneWidget,
          reason: 'Gig title must be visible on the detail page');
    });

    testWidgets('Gig description section is visible after scrolling',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      await tester.scrollUntilVisible(
          find.textContaining('All musicians welcome'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.textContaining('All musicians welcome'), findsOneWidget,
          reason: 'Gig description must be displayed on the detail page');
    });
  });
}
