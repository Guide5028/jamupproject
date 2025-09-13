import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String avatar;
  final String initialStatus; // ✅ pending, confirmed, declined

  const ChatPage({
    super.key,
    required this.name,
    required this.avatar,
    this.initialStatus = "pending",
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  late String bookingStatus;

  final List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    bookingStatus = widget.initialStatus;

    // Add initial system message based on booking status
    _addSystemMessage(bookingStatus);
    // Add some demo chat
    messages.addAll([
      {"fromMe": false, "text": "Hi, are you available this Friday?"},
      {"fromMe": true, "text": "Yes! What time is the show?"},
      {"fromMe": false, "text": "9pm at Saxophone Pub 🎶"},
    ]);
  }

  void _addSystemMessage(String status) {
    String text;
    switch (status) {
      case "confirmed":
        text = "✅ Booking confirmed";
        break;
      case "declined":
        text = "❌ Booking declined";
        break;
      default:
        text = "⏳ Booking request sent (pending)";
    }

    messages.insert(0, {"system": true, "text": text}); // newest system msg at top
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      messages.add({"fromMe": true, "text": _controller.text.trim()});
    });
    _controller.clear();
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: text.startsWith("✅")
              ? Colors.green
              : text.startsWith("❌")
                  ? Colors.red
                  : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.darkBrown),
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
          // 🔹 Booking Status Banner
          _buildStatusBanner(),

          // 🔹 Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                if (msg["system"] == true) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg["text"],
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }
                return ChatBubble(
                  text: msg["text"],
                  fromMe: msg["fromMe"],
                );
              },
            ),
          ),

          // 🔹 Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
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
