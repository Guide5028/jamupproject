import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createBookingAndChat({
    required String gigId,
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final me =
        await supabase.from('users').select('role').eq('id', user.id).single();

    if (me['role'] != 'musician') {
      throw Exception("Only musicians can book gigs");
    }
    // 🔍 check conflict (musician OR venue)
    final conflict = await supabase
        .from('bookings')
        .select('id')
        .eq('status', 'confirmed')
        .or(
          'musician_id.eq.${user.id},venue_id.eq.$venueId',
        )
        .lt('start_time', endTime)
        .gt('end_time', startTime)
        .maybeSingle();

    if (conflict != null) {
      throw Exception('⛔ Time slot already booked');
    }

    // 1) booking
    final booking = await supabase
        .from('bookings')
        .insert({
          'gig_id': gigId,
          'musician_id': user.id,
          'venue_id': venueId,
          'status': 'pending',
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
        })
        .select()
        .single();

    // 2) chat
    final existingChat = await supabase
        .from('chats')
        .select('id')
        .eq('booking_id', booking['id'])
        .maybeSingle();

    String chatId;

    if (existingChat != null) {
      chatId = existingChat['id'].toString();
    } else {
      final chat = await supabase
          .from('chats')
          .insert({'booking_id': booking['id']})
          .select()
          .single();

      chatId = chat['id'].toString();
    }

    // 3) system message
    await sendSystemMessage(chatId: chatId, text: '⏳ Booking request sent');

    return {'booking': booking, 'chatId': chatId};
  }

  /// simple booking create
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

  Future<List<Map<String, dynamic>>> getConfirmedSchedule({
    required String userId,
    required String role, // 'musician' or 'venue'
  }) async {
    final query = supabase
        .from('bookings')
        .select(
          'id, start_time, end_time, gigs(title, location)',
        )
        .eq('status', 'confirmed');

    final res = role == 'musician'
        ? await query.eq('musician_id', userId)
        : await query.eq('venue_id', userId);

    return List<Map<String, dynamic>>.from(res);
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
    required String status,
  }) async {
    if (status == 'confirmed') {
      final booking = await supabase
          .from('bookings')
          .select('start_time, end_time, musician_id, venue_id')
          .eq('id', bookingId)
          .single();

      final start = booking['start_time'];
      final end = booking['end_time'];
      final musicianId = booking['musician_id'];
      final venueId = booking['venue_id'];

      final conflict = await supabase
          .from('bookings')
          .select('id')
          .eq('status', 'confirmed')
          .neq('id', bookingId)
          .or(
            'musician_id.eq.$musicianId,venue_id.eq.$venueId',
          )
          .lt('start_time', end)
          .gt('end_time', start)
          .maybeSingle();

      if (conflict != null) {
        throw Exception('⛔ Time conflict detected');
      }
    }

    await updateBookingStatus(
      bookingId: bookingId,
      status: status,
    );

    final chatId = await getChatIdForBooking(bookingId);
    if (chatId == null) return;

    final text = status == 'confirmed'
        ? '✅ Booking confirmed'
        : status == 'declined'
            ? '❌ Booking declined'
            : '❌ Booking cancelled';

    await sendSystemMessage(chatId: chatId, text: text);
  }

  Future<void> cancelBooking(String bookingId) async {
    await supabase
        .from('bookings')
        .update({'status': 'cancelled'}).eq('id', bookingId);

    final chatId = await getChatIdForBooking(bookingId);
    if (chatId != null) {
      await sendSystemMessage(
        chatId: chatId,
        text: '❌ Booking cancelled',
      );
    }
  }

  Future<void> submitReview({
    required String bookingId,
    required String reviewedUserId,
    required int rating,
    required String comment,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await supabase.from('reviews').insert({
      'booking_id': bookingId,
      'reviewer_id': user.id,
      'reviewed_user_id': reviewedUserId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<bool> hasReviewed({
    required String bookingId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return true;

    final review = await supabase
        .from('reviews')
        .select('id')
        .eq('booking_id', bookingId)
        .eq('reviewer_id', user.id)
        .maybeSingle();

    return review != null;
  }
}
