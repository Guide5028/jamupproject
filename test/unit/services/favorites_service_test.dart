import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/core/services/favorites_service.dart';

void main() {
  // FavoritesService is a singleton, so each test must reset state to
  // avoid order-dependence. setUp runs before EVERY test in this file.
  setUp(() {
    FavoritesService.instance.clear();
  });

  group('FavoritesService — singleton', () {
    test('FavoritesService.instance returns the same object every call', () {
      // `same` checks identity (===), not equality (==).
      expect(
        FavoritesService.instance,
        same(FavoritesService.instance),
      );
    });
  });

  group('FavoritesService — initial state', () {
    test('After clear(), the cache is empty and isLoaded is false', () {
      expect(FavoritesService.instance.ids.value, isEmpty);
      expect(FavoritesService.instance.isLoaded, false);
    });

    test('isFavorite returns false for any id when cache is empty', () {
      expect(FavoritesService.instance.isFavorite('any-gig-id'), false);
    });
  });

  group('FavoritesService — synchronous cache reads', () {
    test('isFavorite reads the in-memory ValueNotifier directly', () {
      // We seed the notifier ourselves to test the read path in isolation
      // (no network). This is the same path the heart-button widget uses.
      FavoritesService.instance.ids.value = {'gig-A', 'gig-C'};

      expect(FavoritesService.instance.isFavorite('gig-A'), true);
      expect(FavoritesService.instance.isFavorite('gig-B'), false);
      expect(FavoritesService.instance.isFavorite('gig-C'), true);
    });
  });

  group('FavoritesService — clear()', () {
    test('clear() removes all ids and resets isLoaded', () {
      FavoritesService.instance.ids.value = {'gig-1', 'gig-2'};

      FavoritesService.instance.clear();

      expect(FavoritesService.instance.ids.value, isEmpty);
      expect(FavoritesService.instance.isLoaded, false);
    });
  });

  group('FavoritesService — reactivity', () {
    test('Listeners on `ids` fire when the value changes', () {
      var fires = 0;
      void listener() => fires++;
      FavoritesService.instance.ids.addListener(listener);

      try {
        FavoritesService.instance.ids.value = {'gig-A'};
        FavoritesService.instance.ids.value = {'gig-A', 'gig-B'};
        FavoritesService.instance.ids.value = <String>{};

        // 3 distinct value writes → 3 listener invocations.
        expect(fires, 3);
      } finally {
        // Always remove listeners we add — leaked listeners across tests
        // cause spooky cross-test interference.
        FavoritesService.instance.ids.removeListener(listener);
      }
    });

    test('Identical value assignments do NOT fire (ValueNotifier short-circuit)',
        () {
      // ValueNotifier only fires when the new value is != the old one.
      // We pin that behaviour because the heart-button relies on it
      // to avoid runaway rebuilds.
      var fires = 0;
      void listener() => fires++;
      final initial = <String>{'gig-A'};
      FavoritesService.instance.ids.value = initial;
      FavoritesService.instance.ids.addListener(listener);

      try {
        FavoritesService.instance.ids.value = initial; // same reference
        expect(fires, 0);
      } finally {
        FavoritesService.instance.ids.removeListener(listener);
      }
    });
  });
}
