import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/venue.dart';
import '../../../models/gig.dart';

class VenueRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<Venue?> fetchVenue(String venueId) async {
    final row = await _db
        .from('users')
        .select('*')
        .eq('id', venueId)
        .maybeSingle();

    if (row == null) return null;
    return Venue.fromJson(row);
  }

  Future<int> fetchGigsHostedCount(String venueId) async {
    final res = await _db
        .from('gigs')
        .select('id')
        .eq('venue_id', venueId);
    return (res as List).length;
  }

  Future<List<Gig>> fetchUpcomingGigs(String venueId) async {
    final rows = await _db
        .from('gigs')
        .select('*')
        .eq('venue_id', venueId)
        .gte('date', DateTime.now().toIso8601String())
        .order('date', ascending: true)
        .limit(5);
    return (rows as List).map((j) => Gig.fromJson(j)).toList();
  }

  Future<List<Gig>> fetchPastGigs(String venueId) async {
    final rows = await _db
        .from('gigs')
        .select('*')
        .eq('venue_id', venueId)
        .lt('date', DateTime.now().toIso8601String())
        .order('date', ascending: false)
        .limit(10);
    return (rows as List).map((j) => Gig.fromJson(j)).toList();
  }
}
