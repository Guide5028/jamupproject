import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../../messages/pages/chat_page.dart';
import '../../booking/data/booking_repository.dart';

class GigDetailPage extends StatelessWidget {
  final Gig gig;
  final BookingRepository bookingRepo = BookingRepository();

  GigDetailPage({super.key, required this.gig});

  Future<void> _bookGig(BuildContext context) async {
    final me = Supabase.instance.client.auth.currentUser;

    // 🔒 Safety check (even if UI fails)
    if (me != null && me.id == gig.venueId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't book your own gig.")),
      );
      return;
    }

    try {
      final result = await bookingRepo.createBookingAndChat(
        gigId: gig.id,
        venueId: gig.venueId,
      );

      final booking = result['booking'] as Map<String, dynamic>;
      final chatId = result['chatId'] as String;

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            name: gig.location,
            avatar: gig.imageUrl,
            initialStatus: booking['status'] ?? 'pending',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final user = Supabase.instance.client.auth.currentUser;
    final role = (user?.userMetadata?['role'] ?? '').toString().toLowerCase();

    final isMusician = role == 'musician';
    final isVenue = role == 'venue';
    final isOwner = isVenue && user?.id == gig.venueId;

    final description = gig.description.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppColors.darkBrown),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.darkBrown),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // 🖼️ Gig Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: gig.imageUrl.isEmpty
                ? _placeholderImage(width * 0.6)
                : Image.network(
                    gig.imageUrl,
                    height: width * 0.6,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(width * 0.6),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎵 Genres
                Wrap(
                  spacing: 8,
                  children: gig.genres.map(_buildTag).toList(),
                ),
                const SizedBox(height: 12),

                // 🏷️ Title
                Text(gig.title, style: AppFonts.textTheme.headlineLarge),
                const SizedBox(height: 8),

                // 📍 Location & Date
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        gig.location,
                        style: AppFonts.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Text(_formatDate(gig.date),
                        style: AppFonts.textTheme.bodyMedium),
                  ],
                ),

                const SizedBox(height: 16),

                // ✅ About (REAL description)
                Text("About Event", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    description.isNotEmpty
                        ? description
                        : "No description provided yet.",
                    style: AppFonts.textTheme.bodyLarge,
                  ),
                ),

                const SizedBox(height: 24),

                // 🎯 Organizer
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryGold,
                      child:
                          Icon(Icons.business, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Organizer"),
                        Text(
                          "Venue / Host",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ✅ ACTION SECTION (professional role-based UI)

                // 1) Musician => show Book Now button
                if (isMusician)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _bookGig(context),
                      child: Text(
                        "Book Now",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // 2) Venue owner => show hosting badge (no booking button)
                if (isOwner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle,
                            color: AppColors.primaryGold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "You are hosting this gig",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Helpers

  Widget _placeholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.music_note, color: AppColors.accentBrown, size: 40),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.darkBrown),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }
}
