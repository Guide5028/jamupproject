// ============================================================================
// gig_repository.dart  —  All DB access that touches the `gigs` table
// ============================================================================
// Teacher note for Guide:
//  • A "repository" is the single class that owns reading/writing one table.
//    UI widgets never call Supabase directly — they go through here. That
//    way, if the schema changes, we only fix ONE file, not ten.
//  • Every method returns a typed `Gig` or `List<Gig>` so the UI never has
//    to remember column names (`json['venue_id']` etc.).
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/gig.dart';

class GigRepository {
  SupabaseClient get supabase => Supabase.instance.client;

  // ───────────────────────────────────────────────────────────────────
  // CREATE  (venue only)
  // ───────────────────────────────────────────────────────────────────
  Future<void> createGig({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required List<String> genres,
    required double latitude,
    required double longitude,
    String imageUrl = '',
    double? payment,
    String? roleNeeded,
    int slots = 1,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // App-layer role guard. RLS is the REAL guard (see gigs_insert_venue_only
    // in the migration), this is just a nicer error message for the UI.
    final me = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = (me?['role'] ?? '').toString().toLowerCase();
    if (role != 'venue') {
      throw Exception('Only venues can create gigs');
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
      'payment': payment,
      'role_needed': roleNeeded,
      'slots': slots,
      if (startTime != null) 'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime.toIso8601String(),
    });
  }

  // ───────────────────────────────────────────────────────────────────
  // UPDATE  (venue, own gigs only)
  // ───────────────────────────────────────────────────────────────────
  Future<void> updateGig({
    required String gigId,
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required List<String> genres,
    String imageUrl = '',
    double? latitude,
    double? longitude,
    double? payment,
    String? roleNeeded,
    int? slots,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // Owner guard in app code for a friendly message.
    final row = await supabase
        .from('gigs')
        .select('venue_id')
        .eq('id', gigId)
        .single();

    if (row['venue_id'].toString() != user.id) {
      throw Exception('You can only edit your own gig');
    }

    // Build payload dynamically so we don't overwrite columns the user
    // didn't touch with `null`.
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'image_url': imageUrl,
      'genres': genres,
    };
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    if (payment != null) payload['payment'] = payment;
    if (roleNeeded != null) payload['role_needed'] = roleNeeded;
    if (slots != null) payload['slots'] = slots;
    if (startTime != null) payload['start_time'] = startTime.toIso8601String();
    if (endTime != null) payload['end_time'] = endTime.toIso8601String();

    await supabase.from('gigs').update(payload).eq('id', gigId);
  }

  // ───────────────────────────────────────────────────────────────────
  // DELETE  (venue, own gigs only, no existing bookings)
  // ───────────────────────────────────────────────────────────────────
  Future<void> deleteGig(String gigId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final row = await supabase
        .from('gigs')
        .select('venue_id')
        .eq('id', gigId)
        .single();

    if (row['venue_id'].toString() != user.id) {
      throw Exception('You can only delete your own gig');
    }

    final bookings =
        await supabase.from('bookings').select('id').eq('gig_id', gigId);

    if ((bookings as List).isNotEmpty) {
      throw Exception(
          "Can't delete a gig with bookings. Cancel them first.");
    }

    await supabase.from('gigs').delete().eq('id', gigId);
  }

  // ───────────────────────────────────────────────────────────────────
  // READ
  // ───────────────────────────────────────────────────────────────────
  Future<List<Gig>> fetchUpcoming({int limit = 10}) async {
    final rows = await supabase
        .from('gigs')
        .select('*')
        .gte('date', DateTime.now().toIso8601String())
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

  Future<List<Gig>> fetchMyGigs(String venueId) async {
    final rows = await supabase
        .from('gigs')
        .select('*')
        .eq('venue_id', venueId)
        .order('date', ascending: false);

    return (rows as List).map((j) => Gig.fromJson(j)).toList();
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
