import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/models/gig.dart';

void main() {

  group('Gig Model Unit Tests', () {

    test('Gig.fromJson parses data correctly', () {

      final json = {
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
        'price': 2500
      };

      final gig = Gig.fromJson(json);

      expect(gig.id, '1');
      expect(gig.title, 'Jazz Night');
      expect(gig.location, 'Chiang Mai');
      expect(gig.genres.contains('Jazz'), true);
      expect(gig.price, 2500);
    });

  });

}