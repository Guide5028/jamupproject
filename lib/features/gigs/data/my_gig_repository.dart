import 'package:supabase_flutter/supabase_flutter.dart';

class MyGigsRepository {
  final supabase = Supabase.instance.client;

  /// Fetch gigs for a given venue, with bookings + musicians
  Future<List<Map<String, dynamic>>> fetchMyGigs(String venueId) async {
    final response = await supabase
        .from('gigs')
        .select('id, title, date, bookings(id, status, musician_id, musicians(name, avatar_url))')
        .eq('venue_id', venueId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update booking status (confirmed/declined)
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await supabase.from('bookings').update({'status': status}).eq('id', bookingId);
  }

  /// Insert a system message in chat
  Future<void> insertSystemMessage(String chatId, String status) async {
    await supabase.from('messages').insert({
      'chat_id': chatId,
      'text': status == "confirmed"
          ? "✅ Booking confirmed"
          : "❌ Booking declined",
      'type': 'system',
    });
  }
}
