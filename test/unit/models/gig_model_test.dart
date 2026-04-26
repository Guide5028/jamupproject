// ============================================================================
// gig_model_test.dart
// ============================================================================
// Why this file exists (teaching note for Guide):
//
//   Gig.fromJson() is the single point where a row from Supabase becomes
//   a Dart object. A bug here is invisible to the compiler — it shows up
//   as silently-wrong UI ("why is this 0?", "why is this null?"). That's
//   exactly the class of bug that destroyed our "X km away" badge for
//   weeks (it was reading json['distance'] when the RPC returned
//   'distance_km'). So Gig.fromJson is exactly the kind of pure
//   data-parsing function where unit tests give the highest value per
//   minute spent. Each test below pins ONE rule that future-you might
//   break.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/models/gig.dart';

void main() {
  group('Gig Model', () {
    test('fromJson parses required fields correctly', () {
      final gig = Gig.fromJson({
        'id': '1',
        'title': 'Jazz Night',
        'description': 'Live jazz music',
        'location': 'Chiang Mai',
        'date': '2026-01-01T20:00:00',
        'image_url': '',
        'genres': ['Jazz'],
        'venue_id': 'venue123',
        'musician_id': 'musician456',
        'latitude': 18.7883,
        'longitude': 98.9853,
        'price': 2500,
      });

      expect(gig.id, '1');
      expect(gig.title, 'Jazz Night');
      expect(gig.location, 'Chiang Mai');
      expect(gig.genres.contains('Jazz'), true);
      expect(gig.price, 2500);
    });

    // The bug we fixed: live RPC returns `distance_km`, but model used
    // to read only `distance`. This test pins the new fallback contract
    // so anyone removing the fallback breaks a test.
    test('fromJson reads distance_km first, then falls back to distance',
        () {
      final fromRpc = Gig.fromJson({
        'id': '1', 'title': 't', 'date': '2026-01-01',
        'distance_km': 4.2,
      });
      expect(fromRpc.distance, 4.2);

      final legacy = Gig.fromJson({
        'id': '2', 'title': 't', 'date': '2026-01-01',
        'distance': 9.9,
      });
      expect(legacy.distance, 9.9);

      final none = Gig.fromJson({
        'id': '3', 'title': 't', 'date': '2026-01-01',
      });
      expect(none.distance, isNull);
    });

    test('fromJson handles missing optional fields with safe defaults', () {
      final gig = Gig.fromJson({
        'id': 'x',
        'title': 'No optionals',
        'date': '2026-05-01',
      });

      expect(gig.description, '');
      expect(gig.location, '');
      expect(gig.imageUrl, '');
      expect(gig.genres, isEmpty);
      expect(gig.price, 0.0);
      expect(gig.payment, isNull);
      expect(gig.roleNeeded, '');
      expect(gig.slots, 0);
      expect(gig.applicants, 0);
    });

    test('fromJson uses now() when date is missing', () {
      final before = DateTime.now();
      final gig = Gig.fromJson({'id': '1', 'title': 't'});
      final after = DateTime.now();

      expect(gig.date.isAfter(before.subtract(const Duration(seconds: 1))),
          true);
      expect(gig.date.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('fromJson coerces numeric values to doubles correctly', () {
      final gig = Gig.fromJson({
        'id': '1', 'title': 't', 'date': '2026-05-01',
        'price': 1500.5,
        'payment': 5000,
      });
      expect(gig.price, 1500.5);
      expect(gig.payment, 5000);
    });

    test('fromJson preserves multiple genres in order', () {
      final gig = Gig.fromJson({
        'id': '1', 'title': 't', 'date': '2026-05-01',
        'genres': ['Jazz', 'Blues', 'Soul'],
      });
      expect(gig.genres, ['Jazz', 'Blues', 'Soul']);
    });

    test('fromJson stringifies non-string ids defensively', () {
      // Postgres uuid columns sometimes deserialize as objects. The model
      // uses .toString() so future-you doesn't get a TypeError.
      final gig = Gig.fromJson({
        'id': 12345,
        'title': 't', 'date': '2026-05-01',
      });
      expect(gig.id, '12345');
    });
  });
}
