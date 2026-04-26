// ============================================================================
// filter_state_test.dart
// ============================================================================
// Why this file exists (teaching note for Guide):
//
//   FilterState is a ChangeNotifier holding 4 sets of selections. Bugs
//   here are sneaky: a missing `notifyListeners()` won't crash, it'll
//   just leave the UI stale. We test the OBSERVABLE behaviour rather
//   than internals — that makes the tests robust to refactoring.
//
//   Each test follows the AAA pattern (Arrange / Act / Assert).
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/core/filters/filter_state.dart';

void main() {
  group('FilterState — Genre toggles', () {
    test('toggleGenre adds genre when not present', () {
      final filter = FilterState();
      filter.toggleGenre('Jazz');

      expect(filter.genres.contains('Jazz'), true);
      expect(filter.genreActive, true);
      expect(filter.hasActive, true);
    });

    test('toggleGenre removes genre when already present', () {
      final filter = FilterState();
      filter.toggleGenre('Jazz');
      filter.toggleGenre('Jazz');

      expect(filter.genres.contains('Jazz'), false);
      expect(filter.genreActive, false);
    });

    test('toggleGenre supports multiple genres simultaneously', () {
      final filter = FilterState();
      filter.toggleGenre('Jazz');
      filter.toggleGenre('Rock');
      filter.toggleGenre('Pop');

      expect(filter.genres.length, 3);
      expect(filter.genres, containsAll(['Jazz', 'Rock', 'Pop']));
    });

    test('removeGenre removes only the specified genre', () {
      final filter = FilterState();
      filter.toggleGenre('Jazz');
      filter.toggleGenre('Rock');
      filter.removeGenre('Jazz');

      expect(filter.genres.contains('Jazz'), false);
      expect(filter.genres.contains('Rock'), true);
    });
  });

  group('FilterState — Type / Location / Price toggles', () {
    test('toggleType adds and removes types correctly', () {
      final filter = FilterState();
      filter.toggleType('Singer');
      expect(filter.types.contains('Singer'), true);
      expect(filter.typeActive, true);

      filter.toggleType('Singer');
      expect(filter.types.contains('Singer'), false);
      expect(filter.typeActive, false);
    });

    test('toggleLocation adds and removes locations correctly', () {
      final filter = FilterState();
      filter.toggleLocation('Bangkok');
      expect(filter.locations.contains('Bangkok'), true);
      expect(filter.locationActive, true);

      filter.toggleLocation('Bangkok');
      expect(filter.locations.contains('Bangkok'), false);
      expect(filter.locationActive, false);
    });

    test('togglePrice adds and removes price buckets correctly', () {
      final filter = FilterState();
      filter.togglePrice('<฿3000');
      expect(filter.prices.contains('<฿3000'), true);
      expect(filter.priceActive, true);

      filter.togglePrice('<฿3000');
      expect(filter.prices.contains('<฿3000'), false);
      expect(filter.priceActive, false);
    });
  });

  group('FilterState — Bulk operations', () {
    test('hasActive is true when ANY filter dimension has selections', () {
      final filter = FilterState();
      expect(filter.hasActive, false);

      filter.toggleType('Singer');
      expect(filter.hasActive, true);

      filter.toggleType('Singer'); // remove
      expect(filter.hasActive, false);

      filter.togglePrice('<฿3000');
      expect(filter.hasActive, true);
    });

    test('clear empties all 4 dimensions in one call', () {
      final filter = FilterState();
      filter.toggleGenre('Jazz');
      filter.toggleType('Band');
      filter.toggleLocation('Bangkok');
      filter.togglePrice('฿10000+');

      filter.clear();

      expect(filter.genres, isEmpty);
      expect(filter.types, isEmpty);
      expect(filter.locations, isEmpty);
      expect(filter.prices, isEmpty);
      expect(filter.hasActive, false);
    });

    test('FilterState fires notifyListeners on each toggle', () {
      // Quickest way to test ChangeNotifier semantics: count how many
      // times the listener fires.
      final filter = FilterState();
      var count = 0;
      filter.addListener(() => count++);

      filter.toggleGenre('Jazz');
      filter.toggleType('Singer');
      filter.toggleLocation('Bangkok');
      filter.togglePrice('<฿3000');

      expect(count, 4);
    });
  });
}
