import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import 'chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations = [
      {
        "name": "Saxophone Pub",
        "lastMessage": "See you at 9pm!",
        "time": "8:45 PM",
        "avatar": "https://via.placeholder.com/150x150.png?text=SP",
      },
      {
        "name": "DJ Nova",
        "lastMessage": "Can you send me the setlist?",
        "time": "7:10 PM",
        "avatar": "https://via.placeholder.com/150x150.png?text=DJ",
      },
      {
        "name": "Luna Jazz Duo",
        "lastMessage": "Looking forward to the gig 🎷",
        "time": "Yesterday",
        "avatar": "https://via.placeholder.com/150x150.png?text=Jazz",
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final convo = conversations[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(convo["avatar"]!),
            ),
            title: Text(convo["name"]!, style: AppFonts.textTheme.bodyLarge),
            subtitle: Text(convo["lastMessage"]!,
                style: AppFonts.textTheme.bodyMedium),
            trailing: Text(convo["time"]!,
                style: AppFonts.textTheme.bodyMedium),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    name: convo["name"]!,
                    avatar: convo["avatar"]!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
