class Gig {
  final String id;
  final String title;
  final String location; // e.g. "Bangkok Jazz Club"
  final DateTime date;   // Supabase stores this as timestamp
  final String imageUrl;
  final List<String> genres; // tags like ["Jazz", "Pop"]
  final String venueId;      // ✅ NEW — owner of the gig

  Gig({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.genres,
    required this.venueId,
  });

  // ✅ Convert JSON → Gig
  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      date: DateTime.parse(json['date'].toString()), // ✅ fixed variable name
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      genres: (json['genres'] is List)
          ? List<String>.from(json['genres'])
          : [],
      venueId: json['venue_id']?.toString() ?? '', // ✅ match Supabase schema
    );
  }

  // ✅ Convert Gig → JSON
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
