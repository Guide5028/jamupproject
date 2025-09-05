class Venue {
  final String id;
  final String name;
  final String type; // Restaurant, Club, Bar
  final String location;
  final String imageUrl;

  Venue({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.imageUrl,
  });
}
