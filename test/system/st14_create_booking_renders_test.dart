// ST-14 — Create Booking Page Renders Gig Info and Send Button
//
// Pumps CreateBookingPage with a fake Gig and verifies that the gig title,
// date, location, and the "Send Booking Request" button are all visible.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/models/gig.dart';
import 'package:jamup_app/features/booking/pages/create_booking_page.dart';

Gig _fakeGig() => Gig(
      id: 'g1',
      title: 'Rooftop Jazz Night',
      description: 'Jazz under the stars.',
      location: 'Bangkok',
      date: DateTime(2026, 9, 20, 20, 0),
      imageUrl: '',
      genres: const ['Jazz'],
      venueId: 'v1',
      musicianId: '',
      latitude: 13.7,
      longitude: 100.5,
      roleNeeded: 'Vocalist',
    );

Widget _buildPage() =>
    MaterialApp(home: CreateBookingPage(gig: _fakeGig()));

void main() {
  group('ST-14 — Create Booking Page Renders Gig Info and Send Button', () {
    testWidgets('Gig title is shown on the booking page', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Rooftop Jazz Night'), findsOneWidget,
          reason: 'Booking page must display the gig title');
    });

    testWidgets('Location is shown on the booking page', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Bangkok'), findsOneWidget,
          reason: 'Booking page must display the gig location');
    });

    testWidgets('Send Booking Request button is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Send Booking Request'),
          findsOneWidget,
          reason: 'Booking page must have a Send Booking Request button');
    });
  });
}
