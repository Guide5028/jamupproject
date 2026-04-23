import 'package:flutter/material.dart';
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
    final startTime = gig.date;
    final endTime = gig.date.add(const Duration(hours: 2));

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
        startTime: startTime,
        endTime: endTime,
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
            otherUserId: '',
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
          SizedBox(
            height: width * 0.65,
            width: double.infinity,
            child: Stack(
              children: [
                // Image
                Positioned.fill(
                  child: gig.imageUrl.isEmpty
                      ? _placeholderImage(width * 0.65)
                      : Image.network(
                          gig.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholderImage(width * 0.65),
                        ),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Title + info on image
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        gig.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              gig.location,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(gig.date),
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoTile(
                      Icons.music_note,
                      "Role",
                      gig.roleNeeded.isNotEmpty ? gig.roleNeeded : "Musician",
                    ),
                    _infoTile(
                      Icons.people,
                      "Slots",
                      "${gig.slots}",
                    ),
                    _infoTile(
                      Icons.payments,
                      "Payment",
                      gig.payment != null
                          ? "\$${gig.payment}"
                          : "Not specified",
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          gig.applicants > 0
                              ? "${gig.applicants} musicians applied"
                              : "Be the first to apply",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 📍 LOCATION + DATE
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        gig.location,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.textTheme.bodyMedium?.copyWith(
                          color: AppColors.accentBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(gig.date),
                      style: AppFonts.textTheme.bodyMedium?.copyWith(
                        color: AppColors.accentBrown,
                      ),
                    ),
                  ],
                ),

                // 📍 DISTANCE
                if (gig.distance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me,
                            size: 14, color: AppColors.primaryGold),
                        const SizedBox(width: 4),
                        Text(
                          "${gig.distance!.toStringAsFixed(1)} km away",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ✅ About (REAL description)
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 6),
              Text("About this gig", style: AppFonts.textTheme.headlineMedium),
            ],
          ),
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
          GestureDetector(
            onTap: () {
              // TODO open venue profile page
            },
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryGold,
                  child: Icon(Icons.business, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Organizer",
                      style: AppFonts.textTheme.bodyMedium,
                    ),
                    Text(
                      gig.location, // temporary venue name
                      style: AppFonts.textTheme.headlineMedium,
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
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
                  style: AppFonts.textTheme.bodyLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
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
    );
  }

  // 🔹 Helpers

  Widget _placeholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child:
          const Icon(Icons.music_note, color: AppColors.accentBrown, size: 40),
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
        style: AppFonts.textTheme.bodyMedium,
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGold),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.accentBrown,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }
}
