class Gig {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final String imageUrl;
  final List<String> genres;

  final String venueId;

  Gig({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.genres,
    required this.venueId, 
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      date: json['date'] is String ? DateTime.parse(json['date']) : (json['date'] as DateTime),
      imageUrl: (json['image_url'] ?? '').toString(),
      genres: (json['genres'] as List?)?.cast<String>() ?? [],

      venueId: (json['venue_id'] ?? '').toString(),
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
      'venue_id': venueId,
    };
  }
}