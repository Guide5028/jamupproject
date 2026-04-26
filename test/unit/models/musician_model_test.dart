import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/models/musician.dart';

void main() {
  group('Musician Model — fromJson', () {
    test('Parses required fields with safe coercion', () {
      final m = Musician.fromJson({
        'id': 42,                       // intentionally a number
        'name': 'Jane Doe',
        'role': 'musician',
        'avatar_url': 'http://x/a.png',
        'bio': 'Singer • Pop',
        'genres': ['Jazz', 'Soul'],
      });

      expect(m.id, '42');
      expect(m.name, 'Jane Doe');
      expect(m.imageUrl, 'http://x/a.png');
      expect(m.genres, ['Jazz', 'Soul']);
    });

    test('Defaults role to "musician" when key is missing', () {
      final m = Musician.fromJson({'id': '1', 'name': 'X'});
      expect(m.role, 'musician');
    });

    test('Empty genres list when key is missing', () {
      final m = Musician.fromJson({'id': '1', 'name': 'X'});
      expect(m.genres, isEmpty);
    });

    test('Optional fields (rating, location, priceRange) survive nulls', () {
      final m = Musician.fromJson({
        'id': '1', 'name': 'X',
        'rating': 4.7,
        'location': 'Chiang Mai',
        'price_range': '\$\$',
      });
      expect(m.rating, 4.7);
      expect(m.location, 'Chiang Mai');
      expect(m.priceRange, '\$\$');
    });

    test('upcomingGigs is always empty in fromJson (fetched separately)',
        () {
      // The repository fetches gigs via a different query — the JSON
      // payload never contains them. This test pins that contract.
      final m = Musician.fromJson({
        'id': '1', 'name': 'X', 'genres': ['Jazz'],
      });
      expect(m.upcomingGigs, isEmpty);
    });
  });

  group('Musician Model — derived getters', () {
    test('primaryGenre returns first genre when list is non-empty', () {
      final m = Musician.fromJson({
        'id': '1', 'name': 'X',
        'genres': ['Jazz', 'Soul'],
      });
      expect(m.primaryGenre, 'Jazz');
      // Backward compatibility alias points to the same value.
      expect(m.genre, 'Jazz');
    });

    test('primaryGenre returns empty string when list is empty', () {
      final m = Musician.fromJson({'id': '1', 'name': 'X'});
      expect(m.primaryGenre, '');
    });

    test('type defers to performance_types[0] when present', () {
      final m = Musician.fromJson({
        'id': '1', 'name': 'X',
        'performance_types': ['Duo', 'Solo'],
      });
      expect(m.type, 'Duo');
    });

    test('type extracts the prefix from bio when "•" separator is used',
        () {
      final m = Musician.fromJson({
        'id': '1', 'name': 'X',
        'bio': 'Band • Wedding specialist',
      });
      expect(m.type, 'Band');
    });

    test('type defaults to "Solo" when neither performance_types nor bio',
        () {
      final m = Musician.fromJson({'id': '1', 'name': 'X'});
      expect(m.type, 'Solo');
    });
  });
}
