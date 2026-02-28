import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/gig.dart';
import 'dart:math';

class GigRepository {
  final supabase = Supabase.instance.client;

  /// ✅ Venue: delete gig (safe + professional)
  Future<void> deleteGig(String gigId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // owner guard
    final row =
        await supabase.from('gigs').select('venue_id').eq('id', gigId).single();

    if (row['venue_id'].toString() != user.id) {
      throw Exception("You can only delete your own gig");
    }

    // prevent deleting gigs that already have bookings
    final bookings =
        await supabase.from('bookings').select('id').eq('gig_id', gigId);

    if ((bookings as List).isNotEmpty) {
      throw Exception("Can't delete gig with bookings. Cancel bookings first.");
    }

    await supabase.from('gigs').delete().eq('id', gigId);
  }

  /// ✅ Venue: update gig (safe)
  Future<void> updateGig({
    required String gigId,
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required List<String> genres,
    String imageUrl = '',
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // owner guard
    final row =
        await supabase.from('gigs').select('venue_id').eq('id', gigId).single();

    if (row['venue_id'].toString() != user.id) {
      throw Exception("You can only edit your own gig");
    }

    await supabase.from('gigs').update({
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'image_url': imageUrl,
      'genres': genres,
    }).eq('id', gigId);
  }

  Future<List<Gig>> fetchUpcoming({int limit = 10}) async {
    final rows = await supabase
        .from('gigs')
        .select('*')
        .gte('date', DateTime.now())
        .order('date', ascending: true)
        .limit(limit);

    return (rows as List).map((j) => Gig.fromJson(j)).toList();
  }

  Future<List<Gig>> fetchAll({String? genre}) async {
    late final List rows;

    if (genre == null || genre.isEmpty) {
      rows = await supabase
          .from('gigs')
          .select('*')
          .order('date', ascending: true);
    } else {
      rows = await supabase
          .from('gigs')
          .select('*')
          .contains('genres', [genre]).order('date', ascending: true);
    }

    return rows.map((j) => Gig.fromJson(j)).toList();
  }

  Future<List<Gig>> fetchNearbyReal({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    final rows =
        await supabase.from('gigs').select('*').gte('date', DateTime.now());

    final gigs = (rows as List).map((j) => Gig.fromJson(j)).toList();

    return gigs.where((gig) {
      if (gig.latitude == null || gig.longitude == null) {
        return false;
      }

      final distance = _calculateDistance(
        latitude,
        longitude,
        gig.latitude!,
        gig.longitude!,
      );

      return distance <= radius;
    }).toList();
  }

  // ✅ NEW: venue fetch own gigs
  Future<List<Gig>> fetchMyGigs(String venueId) async {
    final rows = await supabase
        .from('gigs')
        .select('*')
        .eq('venue_id', venueId)
        .order('date', ascending: false);

    return (rows as List).map((j) => Gig.fromJson(j)).toList();
  }

  // venue create gig
  Future<void> createGig({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required List<String> genres,
    required double latitude,
    required double longitude,
    String imageUrl = '',
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // optional guard (RLS is the real protection)
    final me =
        await supabase.from('users').select('role').eq('id', user.id).single();
    if ((me['role'] ?? '').toString().toLowerCase() != 'venue') {
      throw Exception("Only venues can create gigs");
    }

    await supabase.from('gigs').insert({
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'venue_id': user.id,
      'image_url': imageUrl,
      'genres': genres,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // calculate distance between 2 lat/lng points using Haversine formula
  double _degToRad(double deg) => deg * pi / 180;

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // meters

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }
}
