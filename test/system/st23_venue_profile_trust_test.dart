// ST-23 — Venue Profile Trust Page
//
// Pumps VenueDetailPage with fake repositories and verifies that the three
// trust stat labels (reviews, gigs hosted, member since) are all rendered,
// and that the section headers for Open Gigs and Past Events are present.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/core/constants/app_colors.dart';
import 'package:jamup_app/features/venues/pages/venue_detail_page.dart';
import 'package:jamup_app/features/venues/data/venue_repository.dart';
import 'package:jamup_app/features/reviews/data/review_repository.dart';
import 'package:jamup_app/models/venue.dart';
import 'package:jamup_app/models/gig.dart';

// ── Fake repositories ──────────────────────────────────────────────────────

class _FakeVenueRepo extends VenueRepository {
  @override
  Future<Venue?> fetchVenue(String venueId) async => Venue(
        id: venueId,
        name: 'The Jazz Cellar',
        bio: 'Underground jazz bar in Bangkok',
        imageUrl: '',
        location: 'Bangkok',
        genres: const ['Jazz', 'Blues'],
        createdAt: DateTime(2022, 3, 1),
      );

  @override
  Future<int> fetchGigsHostedCount(String venueId) async => 14;

  @override
  Future<List<Gig>> fetchUpcomingGigs(String venueId) async => [
        _fakeGig('g1', 'Friday Jazz Night',
            DateTime.now().add(const Duration(days: 5))),
        _fakeGig('g2', 'Saturday Blues',
            DateTime.now().add(const Duration(days: 12))),
      ];

  @override
  Future<List<Gig>> fetchPastGigs(String venueId) async => [
        _fakeGig('g3', 'New Year Jazz', DateTime(2025, 12, 31)),
        _fakeGig('g4', 'Summer Session', DateTime(2025, 6, 15)),
      ];

  Gig _fakeGig(String id, String title, DateTime date) => Gig(
        id: id,
        title: title,
        description: '',
        location: 'Bangkok',
        date: date,
        imageUrl: '',
        genres: const ['Jazz'],
        venueId: 'v1',
        musicianId: '',
        latitude: 13.7,
        longitude: 100.5,
        roleNeeded: 'Singer',
      );
}

class _FakeReviewRepo extends ReviewRepository {
  @override
  Future<double> getAverageRating(String userId) async => 4.3;

  @override
  Future<List<Map<String, dynamic>>> getReviews(String userId) async => [
        {'rating': 5, 'comment': 'Amazing venue!'},
        {'rating': 4, 'comment': 'Great sound system'},
      ];
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _buildPage() => MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGold)),
      home: VenueDetailPage(
        venueId: 'v1',
        venueRepo: _FakeVenueRepo(),
        reviewRepo: _FakeReviewRepo(),
      ),
    );

/// Scrolls until [target] is visible, then drains all pending timers
/// (e.g. ReviewWidget's deferred FutureBuilder) so the test ends cleanly.
Future<void> _scrollAndSettle(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 150,
      scrollable: find.byType(Scrollable).first);
  // pumpAndSettle advances time, firing any zero-duration deferred futures
  // created by ReviewWidget while it was lazily built during scroll.
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('ST-23 — Venue Profile Trust Page', () {
    testWidgets('Trust stats card shows all three stat labels', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('gigs hosted'), findsOneWidget,
          reason: 'Trust card must show gigs hosted label');
      expect(find.text('member since'), findsOneWidget,
          reason: 'Trust card must show member since label');
      expect(find.textContaining('review'), findsWidgets,
          reason: 'Trust card must show reviews label');
    });

    testWidgets('Venue name and location are displayed', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('The Jazz Cellar'), findsOneWidget);
      expect(find.text('Bangkok'), findsOneWidget);
    });

    testWidgets('Open Gigs section header is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await _scrollAndSettle(tester, find.text('Open Gigs'));

      expect(find.text('Open Gigs'), findsOneWidget,
          reason: 'Open Gigs section header must be present');
    });

    testWidgets('Past Events section header is present', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await _scrollAndSettle(tester, find.text('Past Events'));

      expect(find.text('Past Events'), findsOneWidget,
          reason: 'Past Events section header must be present');
    });

    testWidgets('Open gig rows show Apply chip', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await _scrollAndSettle(tester, find.text('Apply'));

      expect(find.text('Apply'), findsWidgets,
          reason: 'Each upcoming gig must show an Apply chip');
    });

    testWidgets('Past events show green checkmark icon', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await _scrollAndSettle(tester, find.byIcon(Icons.check_circle_outline));

      expect(find.byIcon(Icons.check_circle_outline), findsWidgets,
          reason: 'Past event rows must have a checkmark icon');
    });
  });
}
