class Gig {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final String imageUrl;
  final List<String> genres;

  Gig({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.genres,
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : (json['date'] as DateTime),    // 👈 FIXED
      imageUrl: json['image_url'] ?? '',
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'genres': genres,
    };
  }
}
