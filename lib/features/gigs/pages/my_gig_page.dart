import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../booking/data/booking_repository.dart';

class MyGigsPage extends StatelessWidget {
  const MyGigsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingController(BookingRepository())
        ..loadBookingsForVenue("mock-venue-id"), // TODO: replace with auth user.id
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
              body: Center(child: Text("No gigs found")),
            );
          }

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
              itemCount: ctrl.bookings.length,
              itemBuilder: (context, i) {
                final booking = ctrl.bookings[i];
                final gig = booking['gigs'] ?? {};
                final musician = booking['musicians'] ?? {};
                final musicianName = musician['name'] ?? "Unknown";
                final avatar =
                    musician['avatar_url'] ?? "https://via.placeholder.com/150";
                final status = booking['status'] ?? "pending";

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
                        Text(gig['title'] ?? "Untitled Gig",
                            style: AppFonts.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(gig['date'] ?? "",
                            style: AppFonts.textTheme.bodyMedium),
                        const Divider(height: 20),

                        // Booking requests
                        ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(avatar)),
                          title: Text(musicianName,
                              style: AppFonts.textTheme.bodyLarge),
                          subtitle: Text("Status: $status",
                              style: AppFonts.textTheme.bodyMedium),
                          trailing: status == "pending"
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle,
                                          color: Colors.green),
                                      onPressed: () {
                                        context
                                            .read<BookingController>()
                                            .updateBookingStatus(
                                              bookingId: booking['id'],
                                              status: "confirmed",
                                            );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatPage(
                                              name: musicianName,
                                              avatar: avatar,
                                              initialStatus: "confirmed",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.red),
                                      onPressed: () {
                                        context
                                            .read<BookingController>()
                                            .updateBookingStatus(
                                              bookingId: booking['id'],
                                              status: "declined",
                                            );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatPage(
                                              name: musicianName,
                                              avatar: avatar,
                                              initialStatus: "declined",
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
                                          name: musicianName,
                                          avatar: avatar,
                                          initialStatus: status,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
