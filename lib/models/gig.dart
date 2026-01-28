class Gig {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String imageUrl;
  final List<String> genres;
  final String venueId;

  Gig({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.genres,
    required this.venueId,
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final parsedDate = rawDate is DateTime
        ? rawDate
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();

    return Gig(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      date: parsedDate,
      imageUrl: (json['image_url'] ?? '').toString(),
      genres: (json['genres'] as List?)?.cast<String>() ?? <String>[],
      venueId: (json['venue_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'genres': genres,
      'venue_id': venueId,
    };
  }
}
