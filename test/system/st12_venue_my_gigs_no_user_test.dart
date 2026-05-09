// ST-12 — Venue My Gigs Page (No Authenticated User)
//
// Pumps VenueMyGigsPage without a Supabase session and verifies that the
// page shows a helpful "sign in" message rather than crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/gigs/pages/venue_my_gigs_page.dart';

Widget _buildPage() => const MaterialApp(home: VenueMyGigsPage());

void main() {
  group('ST-12 — Venue My Gigs Page (No Authenticated User)', () {
    testWidgets('Shows "sign in" message when no user is logged in',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.textContaining('sign in'), findsOneWidget,
          reason:
              'My Gigs page must show a sign-in prompt when user is not authenticated');
    });

    testWidgets('My Gigs app bar title is visible', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('My Gigs'), findsOneWidget,
          reason: 'My Gigs page must always display its app bar title');
    });
  });
}
