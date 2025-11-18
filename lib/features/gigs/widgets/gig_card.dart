import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/gig.dart';
import '../pages/gig_detail_page.dart';

class GigCard extends StatelessWidget {
  final Gig gig;

  const GigCard({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    final hasImage = gig.imageUrl.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GigDetailPage(gig: gig),
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
            // 🔹 Image (with safe placeholder)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: hasImage
                  ? Image.network(
                      gig.imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),

            // 🔹 Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gig.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${gig.location} • ${_shortDate(gig.date)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accentBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple gray note placeholder
  Widget _placeholderImage() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.music_note, color: AppColors.accentBrown),
    );
  }

  static String _shortDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }
}
