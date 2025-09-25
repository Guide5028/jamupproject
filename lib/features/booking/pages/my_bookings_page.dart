import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';
import '../controllers/booking_controller.dart';
import '../data/booking_repository.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingController(BookingRepository())
        ..loadBookingsForMusician("mock-musician-id"), // TODO: replace with auth user.id
      child: Consumer<BookingController>(
        builder: (context, ctrl, _) {
          if (ctrl.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (ctrl.error != null) {
            return Scaffold(
              body: Center(child: Text("Error: ${ctrl.error}")),
            );
          }
          if (ctrl.bookings.isEmpty) {
            return const Scaffold(
              body: Center(child: Text("No bookings found")),
            );
          }

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
              itemCount: ctrl.bookings.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final booking = ctrl.bookings[i];
                final gig = booking['gigs'] ?? {};
                final venue = gig['location'] ?? "Unknown venue";

                // Pick icon color by status
                IconData icon;
                Color color;
                switch (booking["status"]) {
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
                  title: Text(gig["title"] ?? "Untitled gig",
                      style: AppFonts.textTheme.bodyLarge),
                  subtitle: Text(
                    "$venue • ${gig["date"] ?? ""}",
                    style: AppFonts.textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.accentBrown),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          name: venue,
                          avatar: gig["image_url"] ??
                              "https://via.placeholder.com/150.png?text=$venue",
                          initialStatus: booking["status"] ?? "pending",
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
