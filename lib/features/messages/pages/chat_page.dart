import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String avatar;
  final String initialStatus; // pending, confirmed, declined

  final String? chatId;     // null = demo mode
  final String? bookingId;  // optional for later

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
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  late String bookingStatus;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    bookingStatus = widget.initialStatus;

    if (widget.chatId == null) {
      // ✅ demo mode
      messages = [
        {"type": "system", "text": "⏳ Booking request sent (pending)"},
        {"sender_id": "other", "text": "Hi, are you available this Friday?", "type": "user"},
        {"sender_id": "me", "text": "Yes! What time is the show?", "type": "user"},
        {"sender_id": "other", "text": "9pm at Saxophone Pub 🎶", "type": "user"},
      ];
    } else {
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (widget.chatId == null) return;

    final res = await supabase
        .from('messages')
        .select()
        .eq('chat_id', widget.chatId!)
        .order('created_at', ascending: true);

    setState(() {
      messages = List<Map<String, dynamic>>.from(res);
    });
  }

  Future<void> _sendMessage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // demo mode
    if (widget.chatId == null) {
      setState(() {
        messages.add({"sender_id": user.id, "text": text, "type": "user"});
      });
      return;
    }

    await supabase.from('messages').insert({
      'chat_id': widget.chatId,
      'sender_id': user.id,
      'text': text,
      'type': 'user',
    });

    _loadMessages();
  }

  Widget _buildStatusBanner() {
    Color bg;
    String text;

    switch (bookingStatus) {
      case "confirmed":
        bg = Colors.green.withOpacity(0.1);
        text = "✅ Booking confirmed";
        break;
      case "declined":
        bg = Colors.red.withOpacity(0.1);
        text = "❌ Booking declined";
        break;
      default:
        bg = Colors.orange.withOpacity(0.1);
        text = "⏳ Booking pending response from venue";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkBrown),
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.avatar)),
            const SizedBox(width: 8),
            Text(widget.name, style: AppFonts.textTheme.headlineMedium),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBanner(),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];

                if (msg['type'] == 'system') {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text'],
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  );
                }

                final fromMe = msg['sender_id'] == currentUserId || msg['sender_id'] == "me";
                return ChatBubble(text: msg['text'], fromMe: fromMe);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryGold),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
