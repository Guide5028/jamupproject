// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/musician_favorite_button.dart';
import '../../../models/musician.dart';
import '../pages/musician_detail_page.dart';

class MusicianCard extends StatelessWidget {
  final Musician musician;

  const MusicianCard({super.key, required this.musician});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MusicianDetailPage(musician: musician),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 🖼 Background Image
              _buildImage(musician.imageUrl),

              // 🌑 Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
              ),

              // 📍 Distance badge — only visible in Nearby mode.
              // We place it in the top-left corner so it doesn't
              // obscure the name or genre tags at the bottom.
              if (musician.distance != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          "${musician.distance!.toStringAsFixed(1)} km",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ❤️ Favorite heart — top-right corner.
              // A venue taps this to save the musician. It sits in its own
              // Positioned (above the gradient and image) so taps hit the
              // heart, not the card's "open profile" GestureDetector.
              Positioned(
                top: 8,
                right: 8,
                child: MusicianFavoriteButton(musicianId: musician.id),
              ),

              // 📄 Content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      musician.name,
                      style: AppFonts.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Type + Genre
                    Text(
                      "${musician.type} • ${musician.primaryGenre}",
                      style: AppFonts.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Genre tags
                    Wrap(
                      spacing: 6,
                      runSpacing: -8,
                      children: musician.genres.take(3).map((g) {
                        return _buildTag(g);
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    // CTA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          "View Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Image with fallback
  // Same look as before (grey box + person icon when there's no image or it
  // fails), but now cached and downscaled so scrolling the grid stays smooth.
  Widget _buildImage(String url) {
    const fallback = ColoredBox(
      color: Color(0xFF2A2A2A),
      child: Center(
        child: Icon(Icons.person, size: 48, color: Colors.white54),
      ),
    );

    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      displayWidth: 220, // ~ width of one card in the 2-column grid
      errorWidget: fallback,
    );
  }

  // 🔹 Tag pill
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
