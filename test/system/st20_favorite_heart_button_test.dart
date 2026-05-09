// ST-20 — Favorite Heart Button Shows Correct State
//
// Pumps FavoriteHeartButton and verifies that it renders an outline heart
// when the gig is not in the favorites set, and a filled heart after the
// ValueNotifier is updated to include the gig ID.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/core/widgets/favorite_heart_button.dart';
import 'package:jamup_app/core/services/favorites_service.dart';

Widget _buildButton({String gigId = 'g_test'}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: FavoriteHeartButton(gigId: gigId, size: 32),
        ),
      ),
    );

void main() {
  group('ST-20 — Favorite Heart Button Shows Correct State', () {
    setUp(() {
      // Ensure the favorites cache is empty before each test.
      FavoritesService.instance.ids.value = {};
    });

    testWidgets('Outline heart shown when gig is not favorited', (tester) async {
      await tester.pumpWidget(_buildButton());
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget,
          reason:
              'Heart button must show outline icon when gig is not favorited');
    });

    testWidgets('Filled heart shown after favoriting in-memory', (tester) async {
      await tester.pumpWidget(_buildButton(gigId: 'g_fav'));
      await tester.pump();

      // Directly update the ValueNotifier (avoids real Supabase toggle call).
      FavoritesService.instance.ids.value = {'g_fav'};
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget,
          reason:
              'Heart button must show filled icon when gig is in favorites set');
    });

    testWidgets('Heart button widget renders in the widget tree', (tester) async {
      await tester.pumpWidget(_buildButton());
      await tester.pump();

      expect(find.byType(FavoriteHeartButton), findsOneWidget,
          reason: 'FavoriteHeartButton must be present in the widget tree');
    });
  });
}
