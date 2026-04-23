import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/gig.dart';

class GigRepository {
  SupabaseClient get supabase => Supabase.instance.client;

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

    // optional guard (RLS is the real protection)p
        final me = await supabase
    .from('users')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();

if (me == null || me['role'] != 'musician') {
  throw Exception("Only musicians can book gigs");
}
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

  Future<List<Gig>> fetchNearbyGigs({
  required double userLat,
  required double userLng,
  required double radius,
}) async {
  final response = await supabase.rpc(
    'get_nearby_gigs',
    params: {
      'user_lat': userLat,
      'user_lng': userLng,
      'radius_km': radius,
    },
  );

  final rows = List<Map<String, dynamic>>.from(response);
  return rows.map((j) => Gig.fromJson(j)).toList();
}
}
