// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../data/messages_repository.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final repo = MessagesRepository();
  late Future<List<Map<String, dynamic>>> fut;

  @override
  void initState() {
    super.initState();
    fut = repo.fetchConversations();
  }

  Future<void> _refresh() async {
    setState(() => fut = repo.fetchConversations());
    await fut;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Messages",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fut,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Failed to load conversations"),
                  const SizedBox(height: 4),
                  Text("${snap.error}",
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final convos = snap.data ?? [];
          if (convos.isEmpty) {
            return const Center(child: Text("No messages yet"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 12),
              itemCount: convos.length,
              itemBuilder: (context, i) {
                final c = convos[i];
                final name = c['other_name'] as String;
                final avatar = (c['other_avatar'] ?? '').toString();
                final status = c['status'] as String;
                final chatId = c['chat_id'] as String;
                final bookingId = c['booking_id'] as String;
                final int unread = c['unread_count'] ?? 0;
                final lastMessage = c['last_message'] ?? '';
                final lastTime = c['last_message_time'] ?? '';
                return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              chatId: chatId,
                              bookingId: bookingId,
                              name: name,
                              avatar: avatar,
                              initialStatus: status,
                            ),
                          ),
                        ).then((_) {
                          _refresh(); // 🔥 refresh conversations when returning
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              backgroundColor:
                                  AppColors.primaryGold.withOpacity(0.15),
                              child: avatar.isEmpty
                                  ? const Icon(Icons.person,
                                      color: AppColors.darkBrown)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // NAME + TIME
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        name,
                                        style: AppFonts.textTheme.bodyLarge!
                                            .copyWith(
                                          fontWeight: unread > 0
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(lastTime),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // MESSAGE PREVIEW
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: unread > 0
                                                ? Colors.black87
                                                : Colors.grey.shade600,
                                            fontWeight: unread > 0
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (unread > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryGold,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              unread.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ));
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';

    final now = DateTime.now();

    // If today → show time
    if (now.difference(date).inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    }

    // If not today → show date
    return "${date.day}/${date.month}";
  }
}
