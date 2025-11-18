import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/gig.dart';

class GigRepository {
  final supabase = Supabase.instance.client;

  /// Upcoming = gigs in the future, ordered by date
  Future<List<Gig>> fetchUpcoming({int limit = 10}) async {
    final rows = await supabase
        .from('gigs')
        .select('*')
        .gte('date', DateTime.now())
        .order('date', ascending: true)
        .limit(limit);

    return (rows as List).map((j) => Gig.fromJson(j)).toList();
  }

  /// All gigs, optionally filtered by genre
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
          .contains('genres', [genre])
          .order('date', ascending: true);
    }

    return rows.map((j) => Gig.fromJson(j)).toList();
  }

  /// Nearby (for now: just “recent gigs” – we don’t have real geo yet)
  Future<List<Gig>> fetchNearbyMock({int limit = 6}) async {
    final rows = await supabase
        .from('gigs')
        .select('*')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List).map((j) => Gig.fromJson(j)).toList();
  }
}
