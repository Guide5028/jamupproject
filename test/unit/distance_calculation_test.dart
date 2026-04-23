import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/features/gigs/controllers/gig_controller.dart';
import 'package:jamup_app/features/gigs/data/gig_repository.dart';

/// Fake repository so we don't connect to Supabase
class FakeGigRepository extends GigRepository {
  FakeGigRepository() : super();
}

void main() {

  group('Distance Calculation Tests', () {

    test('same coordinates return zero distance', () {

      final controller = GigController(FakeGigRepository());

      final distance = controller.calculateDistance(
        18.7883,
        98.9853,
        18.7883,
        98.9853,
      );

      expect(distance, closeTo(0, 0.001));
    });

    test('Chiang Mai to Bangkok distance is correct', () {

      final controller = GigController(FakeGigRepository());

      final distance = controller.calculateDistance(
        18.7883, // Chiang Mai
        98.9853,
        13.7563, // Bangkok
        100.5018,
      );

      expect(distance, closeTo(580, 50));
    });

  });

}