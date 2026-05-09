// ST-05 — Gig Detail Page Shows Gig Information
//
// Pumps GigDetailPage with a fake Gig and verifies that title, location,
// and the role needed are displayed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/models/gig.dart';
import 'package:jamup_app/features/gigs/pages/gig_detail_page.dart';

Gig _fakeGig() => Gig(
      id: 'g1',
      title: 'Saturday Blues Session',
      description: 'A deep blues evening at our cellar stage.',
      location: 'Chiang Mai',
      date: DateTime(2026, 10, 10, 21, 0),
      imageUrl: '',
      genres: const ['Blues'],
      venueId: 'v1',
      musicianId: '',
      latitude: 18.8,
      longitude: 98.9,
      roleNeeded: 'Guitarist',
      payment: 1800,
    );

Widget _buildPage() =>
    MaterialApp(home: GigDetailPage(gig: _fakeGig()));

void main() {
  group('ST-05 — Gig Detail Page Shows Gig Information', () {
    testWidgets('Gig title is displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Saturday Blues Session'), findsOneWidget,
          reason: 'Gig detail page must show the gig title');
    });

    testWidgets('Gig location is displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.textContaining('Chiang Mai'), findsWidgets,
          reason: 'Gig detail page must show the gig location');
    });

    testWidgets('Role needed is displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.textContaining('Guitarist'), findsWidgets,
          reason: 'Gig detail page must show the role needed');
    });
  });
}
