import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ new
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../../messages/pages/chat_page.dart';

class GigDetailPage extends StatelessWidget {
  final Gig gig;

  const GigDetailPage({super.key, required this.gig});

  Future<void> _bookGig(BuildContext context) async {
    final supabase = Supabase.instance.client;

    try {
      // ✅ Insert booking
      final booking = await supabase.from('bookings').insert({
        'gig_id': gig.id,
        'musician_id': 'mock-musician-id', // TODO: replace with real user ID
        'venue_id': 'mock-venue-id',       // TODO: replace with real venue ID
        'status': 'pending',
      }).select().single();

      // ✅ Create chat linked to booking
      final chat = await supabase.from('chats').insert({
        'booking_id': booking['id'],
      }).select().single();

      // ✅ Insert system message
      await supabase.from('messages').insert({
        'chat_id': chat['id'],
        'text': '⏳ Booking request sent',
        'type': 'system',
      });

      // ✅ Navigate to chat page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            name: gig.location,   // show venue name as chat title
            avatar: gig.imageUrl, // temporary, later use venue logo
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
            child: Image.network(
              gig.imageUrl,
              height: width * 0.6,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // 📄 Gig Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre Tags
                Wrap(
                  spacing: 8,
                  children: gig.genres.map((g) => _buildTag(g)).toList(),
                ),
                const SizedBox(height: 10),

                // Title
                Text(gig.title, style: AppFonts.textTheme.headlineLarge),
                const SizedBox(height: 8),

                // Location + Date
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Text(gig.location, style: AppFonts.textTheme.bodyMedium),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Text(gig.date, style: AppFonts.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 16),

                // About
                Text("About Event", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  "This is a placeholder description for ${gig.title}. "
                  "Hosted at ${gig.location}, featuring amazing performances.",
                  style: AppFonts.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),

                // Organizer
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryGold,
                      child:
                          Icon(Icons.business, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Organizer", style: AppFonts.textTheme.bodyMedium),
                        Text("Venue / Host",
                            style: AppFonts.textTheme.headlineMedium),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Book Button
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
                    child: Text("Book Now",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Tag UI
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.darkBrown)),
    );
  }
}
