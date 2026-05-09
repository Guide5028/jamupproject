import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/models/venue.dart';

void main() {
  group('Venue Model — fromJson required fields', () {
    test('Parses name, bio and imageUrl correctly', () {
      final v = Venue.fromJson({
        'id': 'abc',
        'name': 'The Jazz Cellar',
        'bio': 'Underground jazz bar in Bangkok',
        'avatar_url': 'http://x/venue.png',
        'role': 'venue',
      });

      expect(v.id, 'abc');
      expect(v.name, 'The Jazz Cellar');
      expect(v.bio, 'Underground jazz bar in Bangkok');
      expect(v.imageUrl, 'http://x/venue.png');
    });

    test('id is coerced to String when Supabase returns a non-string', () {
      final v = Venue.fromJson({'id': 99, 'name': 'X'});
      expect(v.id, '99');
    });
  });

  group('Venue Model — fromJson optional fields', () {
    test('location reads location_text first, then falls back to location', () {
      final fromText = Venue.fromJson({
        'id': '1',
        'name': 'X',
        'location_text': 'Chiang Mai',
      });
      expect(fromText.location, 'Chiang Mai');

      final fromLocation = Venue.fromJson({
        'id': '2',
        'name': 'X',
        'location': 'Bangkok',
      });
      expect(fromLocation.location, 'Bangkok');
    });

    test('genres parses text[] correctly', () {
      final v = Venue.fromJson({
        'id': '1',
        'name': 'X',
        'genres': ['Jazz', 'Blues', 'Soul'],
      });
      expect(v.genres, ['Jazz', 'Blues', 'Soul']);
    });

    test('genres defaults to empty list when key is missing', () {
      final v = Venue.fromJson({'id': '1', 'name': 'X'});
      expect(v.genres, isEmpty);
    });

    test('createdAt parses ISO timestamp correctly', () {
      final v = Venue.fromJson({
        'id': '1',
        'name': 'X',
        'created_at': '2024-03-15T10:00:00.000Z',
      });
      expect(v.createdAt, isNotNull);
      expect(v.createdAt!.year, 2024);
      expect(v.createdAt!.month, 3);
      expect(v.createdAt!.day, 15);
    });

    test('createdAt is null when key is missing', () {
      final v = Venue.fromJson({'id': '1', 'name': 'X'});
      expect(v.createdAt, isNull);
    });

    test('createdAt is null when value is not a valid date string', () {
      final v = Venue.fromJson({
        'id': '1',
        'name': 'X',
        'created_at': 'not-a-date',
      });
      expect(v.createdAt, isNull);
    });
  });

  group('Venue Model — fromJson safe defaults for missing fields', () {
    test('All optional fields survive a minimal payload without throwing', () {
      final v = Venue.fromJson({'id': '1', 'name': 'Bare Minimum'});

      expect(v.id, '1');
      expect(v.name, 'Bare Minimum');
      expect(v.bio, '');
      expect(v.imageUrl, '');
      expect(v.location, '');
      expect(v.genres, isEmpty);
      expect(v.createdAt, isNull);
    });

    test('bio defaults to empty string when key is absent', () {
      final v = Venue.fromJson({'id': '1', 'name': 'X'});
      expect(v.bio, '');
    });

    test('imageUrl defaults to empty string when avatar_url is null', () {
      final v = Venue.fromJson({'id': '1', 'name': 'X', 'avatar_url': null});
      expect(v.imageUrl, '');
    });
  });
}
