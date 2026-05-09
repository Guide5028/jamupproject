class Venue {
  final String id;
  final String name;
  final String bio;
  final String imageUrl;
  final String? location;
  final List<String> genres;
  final DateTime? createdAt;

  Venue({
    required this.id,
    required this.name,
    required this.bio,
    required this.imageUrl,
    this.location,
    this.genres = const [],
    this.createdAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      imageUrl: (json['avatar_url'] ?? '').toString(),
      location: (json['location_text'] ?? json['location'] ?? '').toString(),
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
