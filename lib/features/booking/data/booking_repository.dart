import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository {
  final supabase = Supabase.instance.client;

  /// ✅ Create booking + chat + system message
  /// Returns: { booking: {...}, chatId: "..." }
  Future<Map<String, dynamic>> createBookingAndChat({
    required String gigId,
    required String venueId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final me =
        await supabase.from('users').select('role').eq('id', user.id).single();

    if (me['role'] != 'musician') {
      throw Exception("Only musicians can book gigs");
    }

    // 1) booking
    final booking = await supabase
        .from('bookings')
        .insert({
          'gig_id': gigId,
          'musician_id': user.id,
          'venue_id': venueId,
          'status': 'pending',
        })
        .select()
        .single();

    // 2) chat
    final chat = await supabase
        .from('chats')
        .insert({'booking_id': booking['id']})
        .select()
        .single();

    final chatId = chat['id'].toString();

    // 3) system message
    await sendSystemMessage(chatId: chatId, text: '⏳ Booking request sent');

    return {'booking': booking, 'chatId': chatId};
  }

  /// ✅ (Optional) simple booking create if some old controller still calls it
  Future<Map<String, dynamic>> createBooking({
    required String gigId,
    required String musicianId,
    required String venueId,
  }) async {
    final booking = await supabase
        .from('bookings')
        .insert({
          'gig_id': gigId,
          'musician_id': musicianId,
          'venue_id': venueId,
          'status': 'pending',
        })
        .select()
        .single();
    return booking;
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await supabase
        .from('bookings')
        .update({'status': status}).eq('id', bookingId);
  }

  Future<List<Map<String, dynamic>>> getBookingsForMusician(
      String musicianId) async {
    final res = await supabase
        .from('bookings')
        .select('id, status, gigs(id, title, date, location, image_url)')
        .eq('musician_id', musicianId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getBookingsForVenue(String venueId) async {
    final res = await supabase
        .from('bookings')
        .select(
            'id, status, musician_id, users!bookings_musician_id_fkey(id, name, avatar_url), gigs(id, title, date, location, image_url)')
        .eq('venue_id', venueId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<String?> getChatIdForBooking(String bookingId) async {
    final chat = await supabase
        .from('chats')
        .select('id')
        .eq('booking_id', bookingId)
        .maybeSingle();

    return chat?['id']?.toString();
  }

  Future<void> sendSystemMessage({
    required String chatId,
    required String text,
  }) async {
    final user = supabase.auth.currentUser;
    await supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user?.id,
      'text': text,
      'type': 'system',
    });
  }

  Future<void> respondToBooking({
    required String bookingId,
    required String status, // confirmed / declined
  }) async {
    await updateBookingStatus(bookingId: bookingId, status: status);

    final chatId = await getChatIdForBooking(bookingId);
    if (chatId == null) return;

    final text =
        status == 'confirmed' ? '✅ Booking confirmed' : '❌ Booking declined';

    await sendSystemMessage(chatId: chatId, text: text);
  }
}
