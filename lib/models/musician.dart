class Musician {
  final String id;
  final String name;
  final String genre; // e.g. Jazz, EDM, HipHop
  final String type; // e.g. Solo, Duo, Band
  final String imageUrl;

  Musician({
    required this.id,
    required this.name,
    required this.genre,
    required this.type,
    required this.imageUrl,
  });

  // ✅ Convert JSON → Musician
  factory Musician.fromJson(Map<String, dynamic> json) {
    return Musician(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      genre: json['genre'] ?? '',
      type: json['type'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  // ✅ Convert Musician → JSON (for sending data to backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genre': genre,
      'type': type,
      'imageUrl': imageUrl,
    };
  }
}
