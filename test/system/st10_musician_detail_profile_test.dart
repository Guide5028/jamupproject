// ST-10 — Musician Detail Page Shows Profile
//
// Pumps MusicianDetailPage with a fake Musician and verifies that the
// musician's name, bio, and location are displayed.
// pumpAndSettle is called after assertions to drain any deferred
// FutureBuilder errors from repositories that require Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/models/musician.dart';
import 'package:jamup_app/features/musicians/pages/musician_detail_page.dart';

Musician _fakeMusician() => Musician(
      id: 'm1',
      name: 'Nadia Siriwan',
      genres: const ['Jazz', 'Blues'],
      role: 'musician',
      imageUrl: '',
      bio: 'Jazz vocalist with 10 years experience performing across Bangkok.',
      location: 'Bangkok',
      rating: 4.8,
      priceRange: '2000–4000 THB',
    );

Widget _buildPage() =>
    MaterialApp(home: MusicianDetailPage(musician: _fakeMusician()));

void main() {
  group('ST-10 — Musician Detail Page Shows Profile', () {
    testWidgets('Musician name is displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Nadia Siriwan'), findsWidgets,
          reason: 'Musician detail page must display the musician name');

      // Drain deferred FutureBuilder async results to avoid post-test errors.
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('Musician bio is displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.textContaining('Jazz vocalist'), findsOneWidget,
          reason: 'Musician detail page must display the musician bio');

      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('Location is displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.textContaining('Bangkok'), findsWidgets,
          reason: 'Musician detail page must show the musician location');

      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });
}
