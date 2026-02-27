import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String avatar;
  final String initialStatus;

  final String? chatId;
  final String? bookingId;

  const ChatPage({
    super.key,
    required this.name,
    required this.avatar,
    this.initialStatus = "pending",
    this.chatId,
    this.bookingId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  late String bookingStatus;
  List<Map<String, dynamic>> _messages = [];

  StreamSubscription? _messageSubscription;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==============================
  // INIT
  // ==============================

  @override
  void initState() {
    super.initState();
    bookingStatus = widget.initialStatus;

    if (widget.chatId != null) {
      _markMessagesAsRead(); // 🔥 mark once when entering
      _startMessageListener();
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

    _controller.clear();

    if (widget.chatId == null) {
      setState(() {
        _messages.add({
          "sender_id": currentUserId ?? "me",
          "text": text,
          "type": "user",
        });
      });
      _scrollToBottom();
      return;
    }

    await _supabase.from('messages').insert({
      'chat_id': widget.chatId,
      'booking_id': widget.bookingId,
      'sender_id': currentUserId,
      'text': text,
      'type': 'user',
      'created_at': DateTime.now().toIso8601String(),
    });
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
          Expanded(
            child: ListView.builder(
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
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
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

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.parse(timestamp);
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
