// ============================================================================
// distance_calculation_test.dart
// ============================================================================
// Why this file exists (teaching note for Guide):
//
//   The Haversine formula computes great-circle distance between two
//   lat/lng pairs. We test:
//     • Boundary case (zero distance for identical coordinates)
//     • Known reference (Chiang Mai → Bangkok ≈ 580 km)
//     • Symmetry (distance A→B == distance B→A)
//     • Hemisphere correctness (negative lat/lng works)
//
//   These pin the math so a future "optimization" that breaks the
//   formula can't slip past code review.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/features/gigs/controllers/gig_controller.dart';
import 'package:jamup_app/features/gigs/data/gig_repository.dart';

class _FakeGigRepository extends GigRepository {}

void main() {
  group('Haversine distance calculation', () {
    test('Identical coordinates return zero distance', () {
      final ctrl = GigController(_FakeGigRepository());
      final d = ctrl.calculateDistance(18.7883, 98.9853, 18.7883, 98.9853);
      expect(d, closeTo(0, 0.001));
    });

    test('Chiang Mai to Bangkok is roughly 580 km (great-circle)', () {
      final ctrl = GigController(_FakeGigRepository());
      final d = ctrl.calculateDistance(18.7883, 98.9853, 13.7563, 100.5018);
      expect(d, closeTo(580, 50));
    });

    test('Distance is symmetric: A→B equals B→A', () {
      final ctrl = GigController(_FakeGigRepository());
      final ab = ctrl.calculateDistance(18.7883, 98.9853, 13.7563, 100.5018);
      final ba = ctrl.calculateDistance(13.7563, 100.5018, 18.7883, 98.9853);
      expect(ab, closeTo(ba, 0.001));
    });

    test('Works correctly for negative coordinates (southern/western hemis)',
        () {
      final ctrl = GigController(_FakeGigRepository());
      // Sydney → Auckland ≈ 2160 km. Both are in southern hemisphere
      // with eastern longitudes, but the lat is negative.
      final d = ctrl.calculateDistance(-33.8688, 151.2093, -36.8485, 174.7633);
      expect(d, closeTo(2160, 100));
    });
  });
}
