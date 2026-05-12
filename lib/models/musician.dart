import 'gig.dart';

class Musician {
  final String id;
  final String name;
  final List<String> genres;        // Supabase: text[]
  final String role;                // musician / venue
  final String imageUrl;
  final String bio;

  // 🔹 Optional profile data
  final String? location;
  final double? rating;
  final List<String> performanceTypes;
  final String? priceRange;

  // 🔹 Relations
  final List<Gig> upcomingGigs;
  final List<String> mediaImages;

  // 🔹 Distance from user — only set when fetched via get_nearby_musicians RPC.
  //    Null means "all musicians" mode; non-null means nearby mode.
  //    Same pattern as Gig.distance so the rest of the codebase is consistent.
  final double? distance;

  Musician({
    required this.id,
    required this.name,
    required this.genres,
    required this.role,
    required this.imageUrl,
    required this.bio,

    this.location,
    this.rating,
    this.priceRange,
    this.performanceTypes = const [],
    this.upcomingGigs = const [],
    this.mediaImages = const [],
    this.distance,
  });

  // ✅ Primary genre (for cards)
  String get primaryGenre => genres.isNotEmpty ? genres.first : "";

  // ✅ Backward compatibility
  String get genre => primaryGenre;

  // ✅ Derived type (until DB column exists)
  String get type {
    if (performanceTypes.isNotEmpty) return performanceTypes.first;

    final b = bio.trim();
    if (b.contains('•')) {
      return b.split('•').first.trim();
    }
    return "Solo";
  }

  factory Musician.fromJson(Map<String, dynamic> json) {
    return Musician(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'musician').toString(),
      imageUrl: (json['avatar_url'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      genres: (json['genres'] as List?)?.cast<String>() ?? <String>[],

      location: json['location']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      priceRange: json['price_range']?.toString(),
      performanceTypes:
          (json['performance_types'] as List?)?.cast<String>() ?? [],
      mediaImages:
          (json['media_images'] as List?)?.cast<String>() ?? [],

      // ⛔ fetched separately from gigs table
      upcomingGigs: const [],

      // The get_nearby_musicians RPC returns distance_km.
      // We prefer that field name; plain 'distance' is a fallback.
      // Identical logic to Gig.fromJson — keep both in sync.
      distance: (json['distance_km'] as num?)?.toDouble()
          ?? (json['distance'] as num?)?.toDouble(),
    );
  }
}
