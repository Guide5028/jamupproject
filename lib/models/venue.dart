class Venue {
  final String id;
  final String name;
  final String type;
  final String location;
  final String imageUrl;

  Venue({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.imageUrl,
  });

  // Create Venue from JSON
  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      location: json['location'],
      imageUrl: json['imageUrl'],
    );
  }

  // Convert Venue to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'imageUrl': imageUrl,
    };
  }
}
