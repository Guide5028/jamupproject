class Gig {
  final String id;
  final String title;
  final String location; // e.g. "Bangkok Jazz Club"
  final String date;     // keep String for now ("2025-09-07")
  final String imageUrl;
  final List<String> genres; // tags like ["Jazz", "Pop"]

  Gig({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.genres,
  });

  // ✅ Convert JSON → Gig
  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      date: json['date'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      genres: List<String>.from(json['genres'] ?? []),
    );
  }

  // ✅ Convert Gig → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'imageUrl': imageUrl,
      'genres': genres,
    };
  }
}
