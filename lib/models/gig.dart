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

  final String roleNeeded;
  final int slots;
  final double? payment;
  /// How the payment figure is measured. Values: 'per_hour', 'per_day', 'fixed'.
  /// Null means fixed (legacy rows before the column was added).
  final String? paymentUnit;
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
    this.distance,
    this.roleNeeded = '',
    this.slots = 0, 
    this.payment,
    this.paymentUnit,
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
      // The live RPC `get_nearby_gigs` returns this as `distance_km`,
      // but a future RPC or manual query might use plain `distance`.
      // Read both, prefer `distance_km` (the source of truth today).
      // Without this fix, the "X km away" badge was silently always null.
      distance: (json['distance_km'] as num?)?.toDouble()
          ?? (json['distance'] as num?)?.toDouble(),

      roleNeeded: json['role_needed'] ?? '',
      slots: (json['slots'] as num?)?.toInt() ?? 0,
      payment: (json['payment'] as num?)?.toDouble(),
      paymentUnit: json['payment_unit'] as String?,
      applicants: (json['applicants'] as num?)?.toInt() ?? 0,
      
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
