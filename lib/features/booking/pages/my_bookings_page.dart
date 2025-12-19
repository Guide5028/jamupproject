import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';
import '../controllers/booking_controller.dart';
import '../data/booking_repository.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final musicianId =
        user?.id ?? 'mock-musician-id'; // TODO: remove mock after auth

    return ChangeNotifierProvider(
      create: (_) => BookingController(BookingRepository())
        ..loadBookingsForMusician(musicianId),
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
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text("My Bookings"),
                backgroundColor: AppColors.background,
                elevation: 0,
                iconTheme: const IconThemeData(color: AppColors.darkBrown),
              ),
              body: const Center(child: Text("No bookings found")),
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
                final gig = (booking['gigs'] ?? {}) as Map<String, dynamic>;
                final status = (booking['status'] ?? 'pending') as String;
                final venue = (gig['location'] ?? 'Unknown venue') as String;
                final title = (gig['title'] ?? 'Untitled gig') as String;
                final date = (gig['date'] ?? '') as String;
                final avatar = (gig['image_url'] ??
                        'https://via.placeholder.com/150.png?text=$venue')
                    as String;

                // pick icon + color by status
                IconData icon;
                Color color;
                switch (status) {
                  case 'confirmed':
                    icon = Icons.check_circle;
                    color = Colors.green;
                    break;
                  case 'declined':
                    icon = Icons.cancel;
                    color = Colors.red;
                    break;
                  default:
                    icon = Icons.hourglass_bottom;
                    color = Colors.orange;
                }

                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(title, style: AppFonts.textTheme.bodyLarge),
                  subtitle: Text("$venue • $date",
                      style: AppFonts.textTheme.bodyMedium),
                  trailing: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.accentBrown),
                  onTap: () async {
                    final repo = BookingRepository();
                    final bookingId = booking['id'].toString();
                    final chatId = await repo.getChatIdForBooking(bookingId);

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          chatId: chatId,
                          bookingId: bookingId,
                          name: venue,
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
