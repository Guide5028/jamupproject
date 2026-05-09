// ST-09 — Musicians Page Behaviour Without Network
//
// Pumps MusiciansPage and verifies the page renders correctly when the
// Supabase backend is unavailable (test environment). The page should
// display a meaningful error state with a Retry button.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/musicians/pages/musicians_page.dart';

Widget _buildPage() => const MaterialApp(home: MusiciansPage());

void main() {
  group('ST-09 — Musicians Page Behaviour Without Network', () {
    testWidgets('Page renders a Scaffold without crashing', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsOneWidget,
          reason: 'Musicians page must render a Scaffold in all states');
    });

    testWidgets('"Failed to load musicians" error message is displayed',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Failed to load musicians 😵'), findsOneWidget,
          reason:
              'Musicians page must show an error message when the list cannot be loaded');
    });

    testWidgets('Retry button is present in the error state', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Retry'), findsOneWidget,
          reason:
              'Musicians page must show a Retry button so the user can try again');
    });
  });
}
