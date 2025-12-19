import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../booking/data/booking_repository.dart';

class MyGigsPage extends StatelessWidget {
  const MyGigsPage({super.key});

  String _formatDate(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) {
      return "${v.year}-${v.month.toString().padLeft(2,'0')}-${v.day.toString().padLeft(2,'0')}";
    }
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("My Gigs"),
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: Center(
          child: Text("Please sign in to manage your gigs.", style: AppFonts.textTheme.bodyLarge),
        ),
      );
    }

    final venueId = user.id;

    return ChangeNotifierProvider(
      create: (_) => BookingController(BookingRepository())..loadBookingsForVenue(venueId),
      child: Consumer<BookingController>(
        builder: (context, ctrl, _) {
          if (ctrl.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (ctrl.error != null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text("My Gigs"),
                backgroundColor: AppColors.background,
                elevation: 0,
              ),
              body: Center(child: Text("Error: ${ctrl.error}")),
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
            body: ctrl.bookings.isEmpty
                ? const Center(child: Text("No booking requests yet"))
                : RefreshIndicator(
                    onRefresh: () async {
                      await context.read<BookingController>().loadBookingsForVenue(venueId);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: ctrl.bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final b = ctrl.bookings[i];
                        final bookingId = b['id'].toString();
                        final status = (b['status'] ?? 'pending').toString();

                        final gig = (b['gigs'] ?? {}) as Map<String, dynamic>;
                        final title = (gig['title'] ?? 'Untitled gig').toString();
                        final date = _formatDate(gig['date']);

                        // ✅ IMPORTANT: joined musician is "users" (not musicians)
                        final musician = (b['users'] ?? {}) as Map<String, dynamic>;
                        final musicianName = (musician['name'] ?? 'Musician').toString();
                        final musicianAvatar = (musician['avatar_url'] ?? '').toString();

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: AppColors.shadowColor, blurRadius: 5, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppFonts.textTheme.headlineMedium),
                              const SizedBox(height: 4),
                              Text(date, style: AppFonts.textTheme.bodyMedium),
                              const Divider(height: 18),

                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: musicianAvatar.isNotEmpty ? NetworkImage(musicianAvatar) : null,
                                    child: musicianAvatar.isEmpty
                                        ? const Icon(Icons.person, color: AppColors.accentBrown, size: 18)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(musicianName, style: AppFonts.textTheme.bodyLarge),
                                        Text("Status: $status", style: AppFonts.textTheme.bodyMedium),
                                      ],
                                    ),
                                  ),

                                  // ✅ Chat button always
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: AppColors.accentBrown),
                                    onPressed: () async {
                                      final repo = BookingRepository();
                                      final chatId = await repo.getChatIdForBooking(bookingId);
                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            chatId: chatId,
                                            bookingId: bookingId,
                                            name: musicianName,
                                            avatar: musicianAvatar,
                                            initialStatus: status,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              if (status == "pending")
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => context.read<BookingController>().respondToBooking(
                                              bookingId: bookingId,
                                              status: "confirmed",
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
                                        onPressed: () => context.read<BookingController>().respondToBooking(
                                              bookingId: bookingId,
                                              status: "declined",
                                            ),
                                        child: const Text("Decline"),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }
}
