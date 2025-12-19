import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';
import '../controllers/booking_controller.dart';
import '../data/booking_repository.dart';

class VenueBookingsPage extends StatelessWidget {
  const VenueBookingsPage({super.key});

  String _formatDate(dynamic v) {
    if (v == null) return '';
    if (v is DateTime)
      return "${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}";
    final s = v.toString();
    // if it's ISO string, show yyyy-mm-dd
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }
    final venueId = user.id;

    return ChangeNotifierProvider(
      create: (_) =>
          BookingController(BookingRepository())..loadBookingsForVenue(venueId),
      child: Consumer<BookingController>(
        builder: (context, ctrl, _) {
          if (ctrl.loading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (ctrl.error != null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text("Booking Requests"),
                backgroundColor: AppColors.background,
                elevation: 0,
              ),
              body: Center(child: Text("Error: ${ctrl.error}")),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text("Booking Requests"),
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.darkBrown),
            ),
            body: ctrl.bookings.isEmpty
                ? const Center(child: Text("No booking requests yet"))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: ctrl.bookings.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final b = ctrl.bookings[i];
                      final bookingId = b['id'].toString();
                      final status = (b['status'] ?? 'pending').toString();

                      final gig = (b['gigs'] ?? {}) as Map<String, dynamic>;
                      final title = (gig['title'] ?? 'Untitled gig').toString();
                      final venueName = (gig['location'] ?? '').toString();
                      final date = _formatDate(gig['date']);
                      final gigImage = (gig['image_url'] ?? '').toString();

                      // musician info from joined users row
                      final musicianRow =
                          (b['users'] ?? {}) as Map<String, dynamic>;
                      final musicianName =
                          (musicianRow['name'] ?? 'Musician').toString();
                      final musicianAvatar =
                          (musicianRow['avatar_url'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 5,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: musicianAvatar.isNotEmpty
                                      ? NetworkImage(musicianAvatar)
                                      : null,
                                  child: musicianAvatar.isEmpty
                                      ? const Icon(Icons.person,
                                          color: AppColors.accentBrown,
                                          size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(musicianName,
                                      style: AppFonts.textTheme.bodyLarge),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        _statusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(title,
                                style: AppFonts.textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text("$venueName • $date",
                                style: AppFonts.textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final repo = BookingRepository();
                                      final chatId = await repo
                                          .getChatIdForBooking(bookingId);
                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            chatId: chatId,
                                            bookingId: bookingId,
                                            name: musicianName,
                                            avatar: musicianAvatar.isNotEmpty
                                                ? musicianAvatar
                                                : gigImage,
                                            initialStatus: status,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text("Chat"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (status == 'pending') ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => ctrl.respondToBooking(
                                        bookingId: bookingId,
                                        status: 'confirmed',
                                      ),
                                      child: const Text("Confirm"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => ctrl.respondToBooking(
                                        bookingId: bookingId,
                                        status: 'declined',
                                      ),
                                      child: const Text("Decline"),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
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
