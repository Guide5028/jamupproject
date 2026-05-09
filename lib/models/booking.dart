class Booking {
  final String id;
  final String gigId;
  final String musicianId;
  final String venueId;
  String status; // pending, confirmed, declined, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;
  final String chatId;

  Booking({
    required this.id,
    required this.gigId,
    required this.musicianId,
    required this.venueId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.chatId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
  return Booking(
    id: json["id"].toString(),
    gigId: json["gig_id"].toString(),
    musicianId: json["musician_id"].toString(),
    venueId: json["venue_id"].toString(),
    status: json["status"] ?? "pending",
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    chatId: json["chat_id"]?.toString() ?? '',
  );
}

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "gig_id": gigId,
      "musician_id": musicianId,
      "venue_id": venueId,
      "status": status,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "chat_id": chatId,
    };
  }
}
