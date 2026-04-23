import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/core/filters/filter_state.dart';

void main() {

  group('FilterState Unit Tests', () {

    test('toggleGenre adds genre when not present', () {
      final filter = FilterState();

      filter.toggleGenre("Jazz");

      expect(filter.genres.contains("Jazz"), true);
      expect(filter.genreActive, true);
    });

    test('toggleGenre removes genre when already present', () {
      final filter = FilterState();

      filter.toggleGenre("Jazz");
      filter.toggleGenre("Jazz");

      expect(filter.genres.contains("Jazz"), false);
      expect(filter.genreActive, false);
    });

    test('clear removes all filters', () {
      final filter = FilterState();

      filter.toggleGenre("Jazz");
      filter.toggleType("Band");
      filter.toggleLocation("Bangkok");

      filter.clear();

      expect(filter.genres.isEmpty, true);
      expect(filter.types.isEmpty, true);
      expect(filter.locations.isEmpty, true);
      expect(filter.hasActive, false);
    });

  });

}