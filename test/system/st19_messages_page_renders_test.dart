// ST-19 — Messages Page Renders App Bar
//
// Pumps MessagesPage and verifies that the "Messages" app bar title
// is displayed regardless of whether conversations are loaded.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/messages/pages/messages_page.dart';

Widget _buildPage() => const MaterialApp(home: MessagesPage());

void main() {
  group('ST-19 — Messages Page Renders App Bar', () {
    testWidgets('Messages title is visible in the app bar', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      expect(find.text('Messages'), findsOneWidget,
          reason: 'Messages page must display "Messages" in the app bar');
    });

    testWidgets('Messages page renders a body (loading or error)',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();

      // Either a loading indicator or an error message appears while the
      // FutureBuilder waits for (or fails to reach) Supabase.
      final hasLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasError =
          find.textContaining('Failed').evaluate().isNotEmpty ||
          find.textContaining('load').evaluate().isNotEmpty;

      expect(hasLoading || hasError, isTrue,
          reason:
              'Messages page must show a loading or error state while fetching conversations');
    });
  });
}
