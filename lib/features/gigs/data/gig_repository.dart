import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/gig.dart';

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

  Future<List<Gig>> fetchNearbyMock({int limit = 6}) async {
    final rows = await supabase
        .from('gigs')
        .select('*')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List).map((j) => Gig.fromJson(j)).toList();
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

  // ✅ NEW: venue create gig
  Future<void> createGig({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required List<String> genres,
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
    });
  }
}
