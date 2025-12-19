import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/gig.dart';

class GigRepository {
  final supabase = Supabase.instance.client;

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
      rows = await supabase.from('gigs').select('*').order('date', ascending: true);
    } else {
      rows = await supabase
          .from('gigs')
          .select('*')
          .contains('genres', [genre])
          .order('date', ascending: true);
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
    final me = await supabase.from('users').select('role').eq('id', user.id).single();
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
