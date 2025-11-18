class Musician {
  final String id;
  final String name;
  final String genre;   // primary genre (first from genres[])
  final String type;    // Solo / Duo / Band (for now default "Solo")
  final String imageUrl;
  final String bio;

  Musician({
    required this.id,
    required this.name,
    required this.genre,
    required this.type,
    required this.imageUrl,
    required this.bio,
  });

  factory Musician.fromJson(Map<String, dynamic> json) {
    final genres = (json['genres'] as List?)?.cast<String>() ?? const <String>[];

    return Musician(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      genre: genres.isNotEmpty ? genres.first : '',
      // we don’t have a dedicated column yet, so default to "Solo"
      type: (json['musician_type'] ?? 'Solo').toString(),
      imageUrl: (json['avatar_url'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genre': genre,
      'musician_type': type,
      'avatar_url': imageUrl,
      'bio': bio,
    };
  }
}
