import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';


class NearbyService {
  final _supabase = Supabase.instance.client;

  // ─── Nearby Gigs ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getNearbyGigs({
    double radiusKm = 50,
  }) async {
    final Position? pos = await LocationService.getUserLocation();
    if (pos == null) return [];

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

  // ─── Nearby Musicians ─────────────────────────────────────
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

  // ─── Save User Location ───────────────────────────────────
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