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
      id: json["id"],
      gigId: json["gigId"],
      musicianId: json["musicianId"],
      venueId: json["venueId"],
      status: json["status"],
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
      chatId: json["chatId"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "gigId": gigId,
      "musicianId": musicianId,
      "venueId": venueId,
      "status": status,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "chatId": chatId,
    };
  }
}
