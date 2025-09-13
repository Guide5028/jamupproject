import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      {
        "title": "Jazz Night",
        "venue": "Saxophone Pub",
        "date": "Sep 20, 9:00 PM",
        "status": "confirmed"
      },
      {
        "title": "Acoustic Evening",
        "venue": "Brown Sugar Bar",
        "date": "Sep 25, 8:30 PM",
        "status": "pending"
      },
      {
        "title": "HipHop Battle",
        "venue": "Urban Stage",
        "date": "Sep 28, 10:00 PM",
        "status": "declined"
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final b = bookings[i];

          // Pick icon color by status
          IconData icon;
          Color color;
          switch (b["status"]) {
            case "confirmed":
              icon = Icons.check_circle;
              color = Colors.green;
              break;
            case "declined":
              icon = Icons.cancel;
              color = Colors.red;
              break;
            default:
              icon = Icons.hourglass_bottom;
              color = Colors.orange;
          }

          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(b["title"]!, style: AppFonts.textTheme.bodyLarge),
            subtitle: Text("${b["venue"]} • ${b["date"]}",
                style: AppFonts.textTheme.bodyMedium),
            trailing: const Icon(Icons.chat_bubble_outline,
                color: AppColors.accentBrown),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    name: b["venue"]!,
                    avatar:
                        "https://via.placeholder.com/150.png?text=${b["venue"]}",
                    initialStatus: b["status"]!, // ✅ pass booking status
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
