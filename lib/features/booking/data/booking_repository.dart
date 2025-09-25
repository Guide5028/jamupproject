import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository {
  final supabase = Supabase.instance.client;

  /// Create a booking (musician applies to a gig)
  Future<Map<String, dynamic>> createBooking({
    required String gigId,
    required String musicianId,
    required String venueId,
  }) async {
    final response = await supabase
        .from('bookings')
        .insert({
          'gig_id': gigId,
          'musician_id': musicianId,
          'venue_id': venueId,
          'status': 'pending',
        })
        .select()
        .single();

    return response;
  }

  /// Update the booking status (confirmed, declined, etc.)
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);
  }

  /// Get bookings for a specific musician (MyBookingsPage)
  Future<List<Map<String, dynamic>>> getBookingsForMusician(String musicianId) async {
    final response = await supabase
        .from('bookings')
        .select('id, status, gigs(id, title, date, location, image_url)')
        .eq('musician_id', musicianId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get bookings for a specific venue (MyGigsPage)
  Future<List<Map<String, dynamic>>> getBookingsForVenue(String venueId) async {
    final response = await supabase
        .from('bookings')
        .select('id, status, musicians(id, name, avatar_url), gigs(id, title, date)')
        .eq('venue_id', venueId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Delete a booking (optional, in case of cancellation)
  Future<void> deleteBooking(String bookingId) async {
    await supabase.from('bookings').delete().eq('id', bookingId);
  }
}
