class Gig {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String imageUrl;
  final List<String> genres;
  final String venueId;
  final String musicianId; 

  Gig({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.genres,
    required this.venueId,
    required this.musicianId,
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      date: DateTime.parse(json['date']),
      imageUrl: json['image_url'] ?? '',
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
      venueId: json['venue_id'] ?? '',
      musicianId: json['musician_id'] ?? '', // ✅
    );
  }
}
