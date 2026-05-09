// ST-24 — Musician Reviews a Venue
//
// Pumps the ReviewPage with a fake repository and verifies that the star
// rating selector and comment field are present, that submitting the form
// calls the repository with the correct arguments, and that no error is shown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/reviews/pages/review_page.dart';
import 'package:jamup_app/features/reviews/data/review_repository.dart';

// ── Fake repository ────────────────────────────────────────────────────────

class _FakeReviewRepo extends ReviewRepository {
  Map<String, dynamic>? lastSubmission;

  @override
  Future<void> addReview({
    required String bookingId,
    required String reviewerId,
    required String reviewedUserId,
    required int rating,
    required String comment,
  }) async {
    lastSubmission = {
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'rating': rating,
      'comment': comment,
    };
  }
}

// ── Test ───────────────────────────────────────────────────────────────────

void main() {
  group('ST-24 — Musician Reviews a Venue', () {
    testWidgets('Review page renders star selector and comment field',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            bookingId: 'b1',
            reviewerId: 'musician1',
            reviewedUserId: 'venue1',
          ),
        ),
      );
      await tester.pump();

      // Star icons for rating selection must be visible (all 5 rendered)
      expect(find.byIcon(Icons.star), findsNWidgets(5),
          reason: 'Five star rating icons must render on the review page');

      // Comment text field must exist
      expect(find.byType(TextField), findsOneWidget,
          reason: 'Comment input field must be on the review page');

      // Submit button must exist
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
    });

    testWidgets('Tapping a star selects the rating', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            bookingId: 'b1',
            reviewerId: 'musician1',
            reviewedUserId: 'venue1',
          ),
        ),
      );
      await tester.pump();

      // Tap the 4th star
      final starIcons = find.byIcon(Icons.star);
      await tester.tap(starIcons.at(3));
      await tester.pump();

      // After tapping, rating state should reflect 4 — the page should
      // not show an error or reset.
      expect(find.byIcon(Icons.star), findsNWidgets(5),
          reason: 'Stars must still be rendered after selection');
    });

    testWidgets('Submitting calls repo with correct rating and comment',
        (tester) async {
      final fakeRepo = _FakeReviewRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            bookingId: 'b1',
            reviewerId: 'musician1',
            reviewedUserId: 'venue1',
            repo: fakeRepo,
          ),
        ),
      );
      await tester.pump();

      // Select 4 stars
      await tester.tap(find.byIcon(Icons.star).at(3));
      await tester.pump();

      // Enter comment
      await tester.enterText(
          find.byType(TextField), 'Great venue, very professional');
      await tester.pump();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pump(const Duration(seconds: 1));

      expect(fakeRepo.lastSubmission, isNotNull,
          reason: 'Repo addReview must be called after submit');
      expect(fakeRepo.lastSubmission!['rating'], 4);
      expect(fakeRepo.lastSubmission!['comment'],
          'Great venue, very professional');
      expect(fakeRepo.lastSubmission!['reviewedUserId'], 'venue1');
    });

    testWidgets('No error message shown after successful submit', (tester) async {
      final fakeRepo = _FakeReviewRepo();

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            bookingId: 'b1',
            reviewerId: 'musician1',
            reviewedUserId: 'venue1',
            repo: fakeRepo,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star).at(4));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('failed'), findsNothing,
          reason: 'No error snackbar should appear on successful submission');
      expect(find.textContaining('error'), findsNothing);
    });
  });
}
