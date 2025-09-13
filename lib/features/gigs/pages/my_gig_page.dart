import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';

class MyGigsPage extends StatelessWidget {
  const MyGigsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock gigs with requests
    final gigs = [
      {
        "title": "HipHop Battle",
        "date": "Sep 23, 10:00 PM",
        "requests": [
          {"musician": "DJ Nova", "status": "pending"},
          {"musician": "Luna Jazz Duo", "status": "confirmed"},
        ]
      },
      {
        "title": "EDM Festival",
        "date": "Oct 5, 7:00 PM",
        "requests": [
          {"musician": "Pop Queen", "status": "declined"},
        ]
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Gigs"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gigs.length,
        itemBuilder: (context, i) {
          final gig = gigs[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gig["title"] as String, style: AppFonts.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(gig["date"] as String, style: AppFonts.textTheme.bodyMedium),
                  const Divider(height: 20),

                  // Booking requests
                  ...(gig["requests"] as List<Map<String, dynamic>>).map<Widget>((req) {
                    return ListTile(
                      leading: const Icon(Icons.person,
                          color: AppColors.primaryGold),
                      title: Text(req["musician"]!,
                          style: AppFonts.textTheme.bodyLarge),
                      subtitle: Text("Status: ${req["status"]}",
                          style: AppFonts.textTheme.bodyMedium),
                      trailing: req["status"] == "pending"
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          name: req["musician"]!,
                                          avatar:
                                              "https://via.placeholder.com/150.png?text=${req["musician"]}",
                                          initialStatus: "confirmed", // ✅ pass confirmed
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          name: req["musician"]!,
                                          avatar:
                                              "https://via.placeholder.com/150.png?text=${req["musician"]}",
                                          initialStatus: "declined", // ✅ pass declined
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : IconButton(
                              icon: const Icon(Icons.chat,
                                  color: AppColors.accentBrown),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      name: req["musician"]!,
                                      avatar:
                                          "https://via.placeholder.com/150.png?text=${req["musician"]}",
                                      initialStatus: req["status"], // ✅ use existing status
                                    ),
                                  ),
                                );
                              },
                            ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
