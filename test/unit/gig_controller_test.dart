import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/features/gigs/controllers/gig_controller.dart';
import 'package:jamup_app/features/gigs/data/gig_repository.dart';
import 'package:jamup_app/models/gig.dart';

class FakeGigRepository extends GigRepository {

  @override
  Future<List<Gig>> fetchAll({String? genre}) async {
    return [];
  }

  @override
  Future<List<Gig>> fetchUpcoming({int limit = 10}) async {
    return [];
  }

  @override
  Future<List<Gig>> fetchNearbyGigs({
    required double userLat,
    required double userLng,
    required double radius,
  }) async {
    return [];
  }

  @override
  Future<List<Gig>> fetchMyGigs(String venueId) async {
    return [];
  }
}

void main() {

  test('search query updates correctly', () async {

    final controller = GigController(FakeGigRepository());

    controller.setSearchQuery("jazz");

    await Future.delayed(const Duration(milliseconds: 300));

    expect(controller.searchQuery, "jazz");

  });

}