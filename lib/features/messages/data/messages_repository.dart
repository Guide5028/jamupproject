import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/pay_label.dart';

class MessagesRepository {
  SupabaseClient get supabase => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchConversations() async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception("Not logged in");

  final userId = user.id;

  // 1️⃣ Get bookings where I am musician or venue (with the gig's posted
  // rate embedded, so the chat can show "Posted rate: ฿X" for context
  // while musician and venue negotiate).
  final bookingsRes = await supabase
      .from('bookings')
      .select('id, status, musician_id, venue_id, gigs(payment, payment_unit)')
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

    final gigInfo = booking['gigs'] as Map<String, dynamic>?;

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
      'gig_payment': (gigInfo?['payment'] as num?)?.toDouble(),
      'gig_payment_unit': gigInfo?['payment_unit'] as String?,
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

  // ==========================================================================
  // CHAT — everything below is used by ChatPage. Centralising the Supabase
  // calls here (instead of ChatPage calling `_supabase.from(...)` directly)
  // means the page can be pumped in widget tests with a fake repository,
  // matching the pattern already used by BookingRepository/GigRepository.
  // ==========================================================================

  /// Live stream of every message in a chat, oldest first.
  Stream<List<Map<String, dynamic>>> messageStream({required String chatId}) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }

  /// Marks every message NOT sent by the current user as read.
  Future<void> markAsRead({required String chatId}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('chat_id', chatId)
        .neq('sender_id', user.id)
        .isFilter('read_at', null);
  }

  /// Sends a plain text chat message.
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': text,
      'type': 'user',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Sends a structured price offer — a first-class negotiation message
  /// (as opposed to free text) so the recipient sees an Accept/Decline
  /// card with the amount instead of having to parse a sentence.
  Future<void> sendPriceOffer({
    required String chatId,
    required double amount,
    required String unit, // 'per_hour' | 'per_day' | 'fixed'
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': 'Price offer: ${payLabel(amount, unit)}',
      'type': 'offer',
      'offer_amount': amount,
      'offer_unit': unit,
      'offer_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Recipient accepts or declines a pending price offer.
  Future<void> respondToPriceOffer({
    required String messageId,
    required String status, // 'accepted' | 'declined'
  }) async {
    await supabase
        .from('messages')
        .update({'offer_status': status}).eq('id', messageId);
  }

  /// Looks up the booking's musician/venue pair and returns whichever one
  /// is NOT [myUserId] — used when a caller opens a chat without already
  /// knowing the other participant's id.
  Future<String?> resolveReceiverId({
    required String bookingId,
    required String? myUserId,
  }) async {
    try {
      final booking = await supabase
          .from('bookings')
          .select('musician_id, venue_id')
          .eq('id', bookingId)
          .single();

      return booking['musician_id'].toString() == myUserId
          ? booking['venue_id'].toString()
          : booking['musician_id'].toString();
    } catch (_) {
      return null;
    }
  }

  /// Fires the shared `send-notification` Edge Function (bell icon row +
  /// OneSignal push). Best-effort — failures never block a message/offer
  /// from having already been sent.
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await supabase.functions.invoke('send-notification', body: {
      'receiverId': receiverId,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
    });
  }
}
