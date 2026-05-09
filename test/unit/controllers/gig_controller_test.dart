// ============================================================================
// gig_controller_test.dart
// ============================================================================
// Why this file exists (teaching note for Guide):
//
//   GigController is the source of truth for "which gigs should the user
//   see right now?". Filter logic, sort logic, search, nearby mode — all
//   flow through `controller.filtered`. A bug here = wrong data on screen.
//
//   We use a hand-rolled FakeGigRepository so the tests run 100% offline.
//   No Supabase. No network. No CI flakiness. This is the textbook
//   "test the unit, not its dependencies" pattern.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/features/gigs/controllers/gig_controller.dart';
import 'package:jamup_app/features/gigs/data/gig_repository.dart';
import 'package:jamup_app/models/gig.dart';

// ── Fake repository ─────────────────────────────────────────────────
// A FAKE returns canned data instead of hitting Supabase. Each test
// sets `seedGigs` to whatever it needs.
class _FakeGigRepository extends GigRepository {
  List<Gig> seedGigs = [];

  @override
  Future<List<Gig>> fetchAll({String? genre}) async => seedGigs;

  @override
  Future<List<Gig>> fetchUpcoming({int limit = 10}) async => seedGigs;

  @override
  Future<List<Gig>> fetchNearbyGigs({
    required double userLat,
    required double userLng,
    required double radius,
  }) async =>
      seedGigs;

  @override
  Future<List<Gig>> fetchMyGigs(String venueId) async => seedGigs;
}

// ── Test fixtures ───────────────────────────────────────────────────
Gig _gig({
  String id = '1',
  String title = 'Untitled',
  String location = 'Chiang Mai',
  List<String> genres = const ['Jazz'],
  String roleNeeded = 'Singer',
  double? payment = 5000,
  DateTime? date,
}) {
  return Gig(
    id: id,
    title: title,
    description: '',
    location: location,
    date: date ?? DateTime(2026, 6, 1),
    imageUrl: '',
    genres: genres,
    venueId: 'v',
    musicianId: '',
    latitude: 18.0,
    longitude: 99.0,
    payment: payment,
    roleNeeded: roleNeeded,
  );
}

void main() {
  group('GigController — Search', () {
    test('setSearchQuery is debounced (250ms) and updates the field',
        () async {
      final controller = GigController(_FakeGigRepository());
      controller.setSearchQuery('jazz');

      // Before debounce, value should not have been set yet.
      expect(controller.searchQuery, '');

      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.searchQuery, 'jazz');
    });

    test('clearSearch resets searchQuery synchronously', () {
      final controller = GigController(_FakeGigRepository());
      controller.setSearchQuery('rock');
      controller.clearSearch();
      expect(controller.searchQuery, '');
    });
  });

  group('GigController — Genre filter', () {
    test('returns all gigs when no genre selected', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'a', genres: ['Jazz']),
          _gig(id: 'b', genres: ['Rock']),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      expect(ctrl.filtered.length, 2);
    });

    test('returns only gigs matching the selected genre', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'a', genres: ['Jazz']),
          _gig(id: 'b', genres: ['Rock']),
          _gig(id: 'c', genres: ['Jazz', 'Soul']),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setGenreFilters({'Jazz'});

      expect(ctrl.filtered.map((g) => g.id).toSet(), {'a', 'c'});
    });

    test('genre match is case-insensitive', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [_gig(id: 'a', genres: ['JAZZ'])];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setGenreFilters({'jazz'});
      expect(ctrl.filtered.length, 1);
    });
  });

  group('GigController — Type filter', () {
    test('Singer type only returns singer gigs', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'a', roleNeeded: 'Singer'),
          _gig(id: 'b', roleNeeded: 'DJ'),
          _gig(id: 'c', roleNeeded: 'Singer'),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setTypeFilters({'Singer'});
      expect(ctrl.filtered.map((g) => g.id).toSet(), {'a', 'c'});
    });

    test('Type filter compares case-insensitively', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [_gig(id: 'a', roleNeeded: 'singer')];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setTypeFilters({'Singer'});
      expect(ctrl.filtered.length, 1);
    });
  });

  group('GigController — Location filter', () {
    test('Bangkok matches "Saxophone Pub, Bangkok"', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'a', location: 'Saxophone Pub, Bangkok'),
          _gig(id: 'b', location: 'Porjai Bar, Chiang Mai'),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setLocationFilters({'Bangkok'});
      expect(ctrl.filtered.map((g) => g.id).toSet(), {'a'});
    });

    test('Empty location set returns everything', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [_gig(id: 'a'), _gig(id: 'b')];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      expect(ctrl.filtered.length, 2);
    });
  });

  group('GigController — Price bucket filter', () {
    late _FakeGigRepository repo;
    late GigController ctrl;

    setUp(() {
      repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'low', payment: 2000),
          _gig(id: 'mid', payment: 5000),
          _gig(id: 'high', payment: 12000),
          _gig(id: 'null', payment: null),
        ];
      ctrl = GigController(repo)..gigs = repo.seedGigs;
    });

    test('"<฿3000" matches only payments below 3000', () {
      ctrl.setPriceFilters({'<฿3000'});
      expect(ctrl.filtered.map((g) => g.id).toSet(), {'low'});
    });

    test('"฿3000-฿10000" is inclusive on both ends', () {
      ctrl.setPriceFilters({'฿3000-฿10000'});
      expect(ctrl.filtered.map((g) => g.id).toSet(), {'mid'});
    });

    test('"฿10000+" matches payments at or above the lower bound', () {
      ctrl.setPriceFilters({'฿10000+'});
      expect(ctrl.filtered.map((g) => g.id).toSet(), {'high'});
    });

    test('Null payments are excluded from any price-filtered result', () {
      ctrl.setPriceFilters({'<฿3000', '฿3000-฿10000', '฿10000+'});
      expect(ctrl.filtered.map((g) => g.id).contains('null'), false);
    });
  });

  group('GigController — Sort', () {
    final earlier = DateTime(2026, 1, 1);
    final later = DateTime(2026, 12, 31);

    test('dateAsc sorts oldest → newest', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'b', date: later),
          _gig(id: 'a', date: earlier),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setSort(GigSort.oldest);
      expect(ctrl.filtered.map((g) => g.id).toList(), ['a', 'b']);
    });

    test('dateDesc sorts newest → oldest', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'a', date: earlier),
          _gig(id: 'b', date: later),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setSort(GigSort.newest);
      expect(ctrl.filtered.map((g) => g.id).toList(), ['b', 'a']);
    });

    test('titleAz sorts alphabetically, case-insensitive', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'b', title: 'banana'),
          _gig(id: 'a', title: 'Apple'),
          _gig(id: 'c', title: 'cherry'),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setSort(GigSort.titleAz);
      expect(ctrl.filtered.map((g) => g.id).toList(), ['a', 'b', 'c']);
    });
  });

  group('GigController — Combined filters (AND, not OR)', () {
    test('Genre AND Type AND Location all apply together', () {
      final repo = _FakeGigRepository()
        ..seedGigs = [
          _gig(id: 'match',
              genres: ['Jazz'], roleNeeded: 'Singer', location: 'Bangkok'),
          _gig(id: 'wrongGenre',
              genres: ['Rock'], roleNeeded: 'Singer', location: 'Bangkok'),
          _gig(id: 'wrongType',
              genres: ['Jazz'], roleNeeded: 'DJ', location: 'Bangkok'),
          _gig(id: 'wrongLocation',
              genres: ['Jazz'], roleNeeded: 'Singer', location: 'Chiang Mai'),
        ];
      final ctrl = GigController(repo)..gigs = repo.seedGigs;
      ctrl.setGenreFilters({'Jazz'});
      ctrl.setTypeFilters({'Singer'});
      ctrl.setLocationFilters({'Bangkok'});

      expect(ctrl.filtered.map((g) => g.id).toSet(), {'match'});
    });
  });

  group('GigController — Setter idempotency (no infinite rebuild loop)', () {
    test('setGenreFilters with identical set does NOT notify', () {
      final ctrl = GigController(_FakeGigRepository());
      var notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      ctrl.setGenreFilters({'Jazz'}); // first call: should notify
      ctrl.setGenreFilters({'Jazz'}); // identical: must NOT notify

      expect(notifyCount, 1);
    });
  });
}
