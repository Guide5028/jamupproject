import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/musician.dart';

class MusicianDetailPage extends StatelessWidget {
  final Musician musician;

  const MusicianDetailPage({super.key, required this.musician});

  Widget _buildHeaderImage(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (musician.imageUrl.isEmpty) {
      return Container(
        height: width * 0.6,
        width: double.infinity,
        color: const Color(0xFFF2F0EA),
        child: const Center(
          child: Icon(Icons.person, color: AppColors.accentBrown, size: 40),
        ),
      );
    }

    return Image.network(
      musician.imageUrl,
      height: width * 0.6,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: width * 0.6,
          width: double.infinity,
          color: const Color(0xFFF2F0EA),
          child: const Center(
            child: Icon(Icons.person, color: AppColors.accentBrown, size: 40),
          ),
        );
      },
    );
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
          // 🖼️ Musician Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildHeaderImage(context),
          ),

          // 📄 Musician Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                Wrap(
                  spacing: 8,
                  children: [
                    if (musician.type.isNotEmpty) _buildTag(musician.type),
                    if (musician.genre.isNotEmpty) _buildTag(musician.genre),
                  ],
                ),

                const SizedBox(height: 10),

                // Name
                Text(musician.name, style: AppFonts.textTheme.headlineLarge),
                const SizedBox(height: 8),

                // Bio
                Text(
                  musician.bio.isNotEmpty
                      ? musician.bio
                      : "${musician.name} hasn’t added a bio yet.",
                  style: AppFonts.textTheme.bodyLarge,
                ),

                const SizedBox(height: 20),

                // Profile row
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryGold,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Musician Profile",
                            style: AppFonts.textTheme.bodyMedium),
                        Text(musician.name,
                            style: AppFonts.textTheme.headlineMedium),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Book button
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
                    onPressed: () {
                      // TODO: connect booking/messaging
                    },
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Tag widget
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
}
