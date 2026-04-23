import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';

// NearbyService calls the database RPC functions we created.
// It depends on LocationService to get coordinates first,
// then passes them to Supabase which does the distance math.
//
// WHY RPC instead of a normal .select() query?
// A normal query fetches ALL gigs then filters in Flutter.
// An RPC runs the Haversine formula in the database —
// only the nearby rows travel over the network. Much faster.

class NearbyService {
  final _supabase = Supabase.instance.client;

  // ─── NEARBY GIGS ──────────────────────────────────────────
  // Returns gigs sorted by distance from the user.
  // Each result includes a distance_km field so you can
  // show "2.4 km away" on the gig card.
  Future<List<Map<String, dynamic>>> getNearbyGigs({
    double radiusKm = 50,
  }) async {
    // Step 1: Get the user's current GPS position
    // We use YOUR existing LocationService — no duplication!
    final Position? pos = await LocationService.getUserLocation();

    // If location is unavailable (permission denied, GPS off),
    // return empty list — the UI will show normal gigs instead
    if (pos == null) return [];

    // Step 2: Call the Supabase RPC function
    // .rpc() calls a database function by name and passes parameters
    final response = await _supabase.rpc(
      'get_nearby_gigs',
      params: {
        'user_lat': pos.latitude,
        'user_lng': pos.longitude,
        'radius_km': radiusKm,
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // ─── NEARBY MUSICIANS ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getNearbyMusicians({
    double radiusKm = 50,
  }) async {
    final Position? pos = await LocationService.getUserLocation();
    if (pos == null) return [];

    final response = await _supabase.rpc(
      'get_nearby_musicians',
      params: {
        'user_lat': pos.latitude,
        'user_lng': pos.longitude,
        'radius_km': radiusKm,
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // ─── SAVE USER LOCATION ───────────────────────────────────
  // Called once on app startup or when user opens the gigs page.
  // Saves their position to the users table so OTHER users
  // can discover them via get_nearby_musicians().
  // Without this, musicians would never appear in nearby searches.
  Future<void> saveMyLocation() async {
    final Position? pos = await LocationService.getUserLocation();
    if (pos == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('users').update({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    }).eq('id', userId);
  }
}