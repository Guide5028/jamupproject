import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/musician.dart';
import '../pages/musician_detail_page.dart';

class MusicianCard extends StatelessWidget {
  final Musician musician;

  const MusicianCard({super.key, required this.musician});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                musician.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(musician.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("${musician.type} • ${musician.genre}",
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.accentBrown)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
