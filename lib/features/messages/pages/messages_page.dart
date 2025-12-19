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
        title: const Text("Messages"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
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
                  const SizedBox(height: 8),
                  Text("${snap.error}", style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
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
            child: ListView.separated(
              itemCount: convos.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = convos[i];
                final name = c['other_name'] as String;
                final avatar = (c['other_avatar'] ?? '').toString();
                final status = c['status'] as String;
                final chatId = c['chat_id'] as String;
                final bookingId = c['booking_id'] as String;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty ? const Icon(Icons.person, color: AppColors.accentBrown) : null,
                  ),
                  title: Text(name, style: AppFonts.textTheme.bodyLarge),
                  subtitle: Text("Status: $status", style: AppFonts.textTheme.bodyMedium),
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
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
