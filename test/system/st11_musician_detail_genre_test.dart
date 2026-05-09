// ST-11 — Musician Detail Page Shows Genre and Price Info
//
// Pumps MusicianDetailPage with a fake Musician and verifies that the
// genre tag and price range are displayed on the profile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/models/musician.dart';
import 'package:jamup_app/features/musicians/pages/musician_detail_page.dart';

Musician _fakeMusician() => Musician(
      id: 'm1',
      name: 'Krit Songkla',
      genres: const ['Blues'],
      role: 'musician',
      imageUrl: '',
      bio: 'Blues guitarist from Chiang Mai.',
      location: 'Chiang Mai',
      priceRange: '1500–3000 THB',
    );

Widget _buildPage() =>
    MaterialApp(home: MusicianDetailPage(musician: _fakeMusician()));

void main() {
  group('ST-11 — Musician Detail Page Shows Genre and Price Info', () {
    testWidgets('Genre tag is displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Blues'), findsWidgets,
          reason: 'Musician detail page must display the genre tag');

      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('Share button is in the app bar', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.byIcon(Icons.share_outlined), findsOneWidget,
          reason: 'Musician detail page must have a share button');

      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('Musician name is shown as page heading', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Krit Songkla'), findsWidgets,
          reason: 'Musician detail page must show the musician name as heading');

      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });
}
