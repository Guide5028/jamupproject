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
  final double? latitude;
  final double? longitude;
  double? distance;
  final double price;

  final String roleNeeded;
  final int slots;
  final double? payment;
  final int applicants;

  final DateTime? createdAt;
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
    required this.latitude,
    required this.longitude,
    required this.price,
    this.distance,
    this.roleNeeded = '',
    this.slots = 0, 
    this.payment,
    this.applicants = 0,
    this.createdAt,
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',

      date: json['date'] != null
    ? DateTime.parse(json['date'])
    : DateTime.now(),

      imageUrl: json['image_url'] ?? '',

      genres: (json['genres'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
    [],

      venueId: json['venue_id'] ?? '',
      musicianId: json['musician_id'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,

      roleNeeded: json['role_needed'] ?? '',
      slots: (json['slots'] as num?)?.toInt() ?? 0,
      payment: (json['payment'] as num?)?.toDouble(),
      applicants: (json['applicants'] as num?)?.toInt() ?? 0,
      
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
