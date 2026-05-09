// ST-04 — Gig Card Renders Key Information
//
// Pumps a GigCard with a fake Gig and verifies that the title, location,
// and payment label are all visible to the user.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/models/gig.dart';
import 'package:jamup_app/features/gigs/widgets/gig_card.dart';

Gig _fakeGig() => Gig(
      id: 'g1',
      title: 'Friday Jazz Night',
      description: 'A great jazz session in the city',
      location: 'Bangkok',
      date: DateTime(2026, 9, 5),
      imageUrl: '',
      genres: const ['Jazz'],
      venueId: 'v1',
      musicianId: '',
      latitude: 13.7,
      longitude: 100.5,
      roleNeeded: 'Vocalist',
      payment: 2500,
      paymentUnit: 'fixed',
    );

Widget _buildCard() => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: GigCard(gig: _fakeGig()),
        ),
      ),
    );

void main() {
  group('ST-04 — Gig Card Renders Key Information', () {
    testWidgets('Gig card shows the gig title', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pump();

      expect(find.text('Friday Jazz Night'), findsOneWidget,
          reason: 'Gig card must display the gig title');
    });

    testWidgets('Gig card shows the location', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pump();

      expect(find.text('Bangkok'), findsOneWidget,
          reason: 'Gig card must display the venue location');
    });

    testWidgets('Gig card shows the genre badge', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pump();

      expect(find.text('Jazz'), findsOneWidget,
          reason: 'Gig card must show the primary genre badge');
    });
  });
}
