import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/musician.dart';
import '../pages/musician_detail_page.dart';

class MusicianCard extends StatelessWidget {
  final Musician musician;

  const MusicianCard({super.key, required this.musician});

  // 🔹 Safe image widget: shows icon if URL missing or fails
  Widget _buildMusicianImage(String? url, {double height = 110}) {
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFF2F0EA),
        child: const Center(
          child: Icon(Icons.person, color: AppColors.accentBrown, size: 32),
        ),
      );
    }

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: double.infinity,
          color: const Color(0xFFF2F0EA),
          child: const Center(
            child: Icon(Icons.person, color: AppColors.accentBrown, size: 32),
          ),
        );
      },
    );
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildMusicianImage(musician.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    musician.name,
                    style: AppFonts.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${musician.type} • ${musician.genre}",
                    style: AppFonts.textTheme.bodyMedium?.copyWith(
                      color: AppColors.accentBrown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
