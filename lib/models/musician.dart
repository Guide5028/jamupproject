class Musician {
  final String id;
  final String name;
  final List<String> genres;     // from users.genres (text[])
  final String venueType;
  final String role;             // musician/venue
  final String imageUrl;
  final String bio;

  Musician({
    required this.id,
    required this.name,
    required this.genres,
    required this.venueType,
    required this.role,
    required this.imageUrl,
    required this.bio,
  });

  // ✅ new
  String get primaryGenre => genres.isNotEmpty ? genres.first : "";

  // ✅ backward-compat so old UI code still works
  String get genre => primaryGenre;

  // ✅ if you don’t have musician_type column, derive from bio like "Solo • EDM"
  String get type {
    final b = bio.trim();
    if (b.contains('•')) return b.split('•').first.trim(); // "Solo", "Duo", "Band"
    return "Solo";
  }

  factory Musician.fromJson(Map<String, dynamic> json) {
    return Musician(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'musician').toString(),
      imageUrl: (json['avatar_url'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      venueType: (json['venue_type'] ?? '').toString(),
      genres: (json['genres'] as List?)?.cast<String>() ?? <String>[],
    );
  }
}
