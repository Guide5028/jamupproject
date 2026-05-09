import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesRepository {
  SupabaseClient get supabase => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchConversations() async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception("Not logged in");

  final userId = user.id;

  // 1️⃣ Get bookings where I am musician or venue
  final bookingsRes = await supabase
      .from('bookings')
      .select('id, status, musician_id, venue_id')
      .or('musician_id.eq.$userId,venue_id.eq.$userId');

  final bookings = List<Map<String, dynamic>>.from(bookingsRes);
  if (bookings.isEmpty) return [];

  final result = <Map<String, dynamic>>[];

  for (final booking in bookings) {
    final bookingId = booking['id'].toString();
// TEMPORARY until we connect real logic

    // 2️⃣ Get chat for this booking
    final chatRes = await supabase
        .from('chats')
        .select('id')
        .eq('booking_id', bookingId)
        .maybeSingle();

    if (chatRes == null) continue;

    final chatId = chatRes['id'].toString();

    // 3️⃣ Get other user
    final isMeMusician =
        booking['musician_id'].toString() == userId;

    final otherId = isMeMusician
        ? booking['venue_id'].toString()
        : booking['musician_id'].toString();

    final otherUser = await supabase
        .from('users')
        .select('name, avatar_url')
        .eq('id', otherId)
        .maybeSingle();
    if (otherUser == null) continue;

    // 4️⃣ Get latest message
    final lastMessageRes = await supabase
        .from('messages')
        .select('text, created_at')
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .limit(1);

    String lastMessage = '';
    String lastTime = '';

    if (lastMessageRes.isNotEmpty) {
      lastMessage = lastMessageRes.first['text'] ?? '';
      lastTime = lastMessageRes.first['created_at'] ?? '';
    }

    // 5️⃣ Count unread
    final unreadRes = await supabase
    .from('messages')
    .select('id')
    .eq('chat_id', chatId)
    .neq('sender_id', userId)
    .isFilter('read_at', null);

    final unreadCount = unreadRes.length;

    result.add({
      'chat_id': chatId,
      'booking_id': bookingId,
      'status': booking['status'] ?? 'pending',
      'other_name': otherUser['name'] ?? 'Chat',
      'other_avatar': otherUser['avatar_url'] ?? '',
      'last_message': lastMessage,
      'last_message_time': lastTime,
      'unread_count': unreadCount,
      'is_musician': isMeMusician,
    });
  }

  // 6️⃣ Sort by latest message time
  result.sort((a, b) {
  final aTime = DateTime.tryParse(a['last_message_time'] ?? '');
  final bTime = DateTime.tryParse(b['last_message_time'] ?? '');

  if (aTime == null && bTime == null) return 0;
  if (aTime == null) return 1;
  if (bTime == null) return -1;

  return bTime.compareTo(aTime);
});

  return result;
}
}
