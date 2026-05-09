// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../../booking/data/booking_repository.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String avatar;
  final String initialStatus;

  final String? chatId;
  final String? bookingId;
  final String otherUserId;
  final bool isVenue;

  const ChatPage({
    super.key,
    required this.name,
    required this.avatar,
    this.initialStatus = "pending",
    this.chatId,
    this.bookingId,
    required this.otherUserId,
    this.isVenue = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final BookingRepository bookingRepo = BookingRepository();

  late String bookingStatus;
  List<Map<String, dynamic>> _messages = [];
  String _receiverId = ''; // resolved at init — used for notifications

  StreamSubscription? _messageSubscription;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Returns the role of the currently logged-in user.
  /// We read it straight from Supabase auth metadata — same place it was
  /// written during sign-up (see auth_service.dart line 40: 'role': role).
  /// No extra network call needed; the metadata is already in memory.
  String get _currentUserRole =>
      (_supabase.auth.currentUser?.userMetadata?['role'] ?? '')
          .toString()
          .toLowerCase();

  // ==============================
  // INIT
  // ==============================

  @override
  void initState() {
    super.initState();
    bookingStatus = widget.initialStatus;
    _receiverId = widget.otherUserId;

    if (widget.chatId != null) {
      _markMessagesAsRead(); // 🔥 mark once when entering
      _startMessageListener();
      // If the caller didn't supply the other user's ID, resolve it from
      // the booking so notifications have a valid receiverId.
      if (_receiverId.isEmpty && widget.bookingId != null) {
        _resolveReceiverId();
      }
    } else {
      _loadDemoMessages();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==============================
  // MESSAGE LOGIC
  // ==============================
  Future<void> _markMessagesAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null || widget.chatId == null) return;

    await _supabase
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('chat_id', widget.chatId!)
        .neq('sender_id', user.id)
        .isFilter('read_at', null);
  }

  /// Looks up musician_id / venue_id from the booking and picks
  /// whichever one is NOT the current user. Called once on init when
  /// the caller didn't pass otherUserId.
  Future<void> _resolveReceiverId() async {
    try {
      final booking = await _supabase
          .from('bookings')
          .select('musician_id, venue_id')
          .eq('id', widget.bookingId!)
          .single();

      final myId = currentUserId;
      _receiverId = booking['musician_id'].toString() == myId
          ? booking['venue_id'].toString()
          : booking['musician_id'].toString();
    } catch (_) {
      // Non-fatal — message still sends, notification just won't fire.
    }
  }

  void _loadDemoMessages() {
    _messages = [
      {"type": "system", "text": "⏳ Booking request sent"},
      {
        "sender_id": "other",
        "text": "Hi, are you available this Friday?",
        "type": "user"
      },
      {
        "sender_id": "me",
        "text": "Yes! What time is the show?",
        "type": "user"
      },
    ];
  }

  void _startMessageListener() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final currentUserId = user.id;

    _messageSubscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId!)
        .order('created_at')
        .listen((data) async {
          final messages = List<Map<String, dynamic>>.from(data);

          // 🔧 Sort messages by time
          messages.sort((a, b) => DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));

          setState(() {
            _messages = messages;
          });

          // 🔥 only check unread messages
          final unread = messages.where((msg) =>
              msg['sender_id'] != currentUserId && msg['read_at'] == null);

          if (unread.isNotEmpty) {
            await _supabase
                .from('messages')
                .update({'read_at': DateTime.now().toIso8601String()})
                .eq('chat_id', widget.chatId!)
                .neq('sender_id', currentUserId)
                .isFilter('read_at', null);
          }

          _scrollToBottom();
        });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _controller.clear();

    if (widget.chatId == null) {
      setState(() {
        _messages.add({
          "sender_id": user.id,
          "text": text,
          "type": "user",
        });
      });
      _scrollToBottom();
      return;
    }

    try {
      await _supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': user.id,
        'text': text,
        'type': 'user',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Call the unified `send-notification` Edge Function.
      // It does TWO things for us:
      //   1) inserts a row into `notifications` (fills the bell icon)
      //   2) sends the OneSignal push banner
      // We pass receiverId directly — ChatPage already knows who the
      // other participant is via widget.otherUserId.
      if (_receiverId.isNotEmpty) {
        final senderName =
            (user.userMetadata?['name'] as String?)?.isNotEmpty == true
                ? user.userMetadata!['name'] as String
                : user.email ?? 'Someone';

        await _supabase.functions.invoke(
          'send-notification',
          body: {
            'receiverId': _receiverId,
            'title': 'New message from $senderName',
            'body': text,
            'type': 'message',
            'data': {
              'chatId': widget.chatId,
              'bookingId': widget.bookingId,
            },
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==============================
  // STATUS BANNER
  // ==============================

  Widget _buildStatusBanner() {
    if (widget.bookingId == null) return const SizedBox();

    Color color;
    String text;

    switch (bookingStatus) {
      case "confirmed":
        color = Colors.green;
        text = "Booking Confirmed";
        break;
      case "declined":
        color = Colors.red;
        text = "Booking Declined";
        break;
      default:
        color = Colors.orange;
        text = "Waiting for confirmation";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==============================
  // UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGold,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.avatar.isNotEmpty ? NetworkImage(widget.avatar) : null,
              child: widget.avatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const Text("Online",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBanner(),
          _buildBookingActions(),
          Expanded(
            child: ListView.builder(
              reverse: false,
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isLast = index == _messages.length - 1;

                if (msg['type'] == 'system') {
                  return _buildSystemMessage(msg['text']);
                }

                final isMe = msg['sender_id'] == currentUserId ||
                    msg['sender_id'] == "me";

                final isRead = msg['read_at'] != null;

                return ChatBubble(
                  message: msg['text'] ?? '',
                  isMe: isMe,
                  time: _formatTime(msg['created_at']),
                  isRead: isRead,
                  readAt: msg['read_at'],
                  showSeen: isMe && isLast && isRead,
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade400)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    if (bookingStatus == "declined") {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Type your message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBookingActions() {
    if (widget.bookingId == null) return const SizedBox();

    if (!widget.isVenue) return const SizedBox();

    if (bookingStatus != "pending") return const SizedBox();

    // ✅ ROLE GUARD — only the venue owner can accept or decline a booking.
    // A musician sent this request; they should not see these action buttons.
    // This mirrors the same check in booking_detail_page.dart (line 96):
    //   if (status == 'pending' && role == 'venue')
    if (_currentUserRole != 'venue') return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                await bookingRepo.respondToBooking(
                  bookingId: widget.bookingId!,
                  status: "confirmed",
                );

                setState(() {
                  bookingStatus = "confirmed";
                });
              },
              child: const Text("Accept"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                await bookingRepo.respondToBooking(
                  bookingId: widget.bookingId!,
                  status: "declined",
                );

                setState(() {
                  bookingStatus = "declined";
                });
              },
              child: const Text("Decline"),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp)
          .toLocal(); // also convert to local timezone!
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }
}
