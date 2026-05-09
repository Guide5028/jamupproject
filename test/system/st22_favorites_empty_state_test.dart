// ST-22 — Favorites Page Shows Empty State
//
// Pumps FavoritesPage with an empty FavoritesService cache and verifies
// that the "No favorites yet" empty-state message is displayed.
// FavoritesService.loadAll() calls Supabase asynchronously; the FutureBuilder
// shows an error or empty result, which both fall through to the empty state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/favorites/pages/favorites_page.dart';
import 'package:jamup_app/core/services/favorites_service.dart';

Widget _buildPage() => const MaterialApp(home: FavoritesPage());

void main() {
  group('ST-22 — Favorites Page Shows Empty State', () {
    setUp(() {
      // Start each test with an empty favorites set.
      FavoritesService.instance.ids.value = {};
    });

    testWidgets('Favorites app bar title is visible', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Favorites'), findsOneWidget,
          reason: 'Favorites page must show "Favorites" in the app bar');
    });

    testWidgets('"No favorites yet" message appears after loading', (tester) async {
      await tester.pumpWidget(_buildPage());
      // Let the FutureBuilder complete (loadAll fails → listFavoriteGigs
      // returns empty because ids set is empty) — either way empty state shows.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('No favorites yet'), findsOneWidget,
          reason:
              'Favorites page must show "No favorites yet" when the list is empty');
    });

    testWidgets('Empty state guidance text is shown', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('Tap the heart'), findsOneWidget,
          reason:
              'Empty state must guide the user to tap the heart on a gig');
    });
  });
}
