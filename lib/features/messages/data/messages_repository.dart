import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesRepository {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // 1) bookings where I'm musician OR venue
    final bookingsRes = await supabase
        .from('bookings')
        .select('id, status, musician_id, venue_id, created_at')
        .or('musician_id.eq.${user.id},venue_id.eq.${user.id}')
        .order('created_at', ascending: false);

    final bookings = List<Map<String, dynamic>>.from(bookingsRes);
    if (bookings.isEmpty) return [];

    final bookingIds = bookings.map((b) => b['id'].toString()).toList();

    // 2) fetch all chats for these bookings (one query)
    final chatsRes = await supabase
        .from('chats')
        .select('id, booking_id, created_at')
        .inFilter('booking_id', bookingIds);

    final chats = List<Map<String, dynamic>>.from(chatsRes);

    // map booking_id -> chat_id
    final Map<String, String> bookingToChat = {
      for (final c in chats)
        c['booking_id'].toString(): c['id'].toString(),
    };

    // 3) collect all "other" user ids (one list)
    final otherIds = <String>{};
    for (final b in bookings) {
      final isMeMusician = b['musician_id'].toString() == user.id;
      final otherId =
          isMeMusician ? b['venue_id'].toString() : b['musician_id'].toString();
      otherIds.add(otherId);
    }

    // 4) fetch all users for those ids (one query)
    final usersRes = await supabase
        .from('users')
        .select('id, name, avatar_url')
        .inFilter('id', otherIds.toList());

    final users = List<Map<String, dynamic>>.from(usersRes);

    final Map<String, Map<String, dynamic>> userById = {
      for (final u in users) u['id'].toString(): u,
    };

    // 5) build result
    final result = <Map<String, dynamic>>[];

    for (final b in bookings) {
      final bookingId = b['id'].toString();
      final chatId = bookingToChat[bookingId];
      if (chatId == null) continue;

      final isMeMusician = b['musician_id'].toString() == user.id;
      final otherId =
          isMeMusician ? b['venue_id'].toString() : b['musician_id'].toString();

      final other = userById[otherId];

      result.add({
        'chat_id': chatId,
        'booking_id': bookingId,
        'status': (b['status'] ?? 'pending').toString(),
        'other_name': (other?['name'] ?? 'Chat').toString(),
        'other_avatar': (other?['avatar_url'] ?? '').toString(),
      });
    }

    return result;
  }
}
