// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/pay_label.dart';
import '../../../core/widgets/favorite_heart_button.dart';
import '../../../models/gig.dart';
import '../pages/gig_detail_page.dart';

class GigCard extends StatelessWidget {
  final Gig gig;
  final String? distanceLabel;

  const GigCard({super.key, required this.gig, this.distanceLabel});

  @override
  Widget build(BuildContext context) {
    final hasImage = gig.imageUrl.trim().isNotEmpty;
    final primaryGenre = gig.genres.isNotEmpty ? gig.genres.first : "";

    return AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: 1.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                /// Image
                Positioned.fill(
                  child: hasImage
                      ? Image.network(
                          gig.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.music_note),
                        ),
                ),

                /// Gradient overlay (like musician page)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// Genre badge
                if (primaryGenre.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        primaryGenre,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                if (distanceLabel != null)
                  Positioned(
                    top: 10,
                    right: 10,
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
                              size: 10, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            distanceLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Heart sits in the OPPOSITE corner from the distance badge
                // so they never collide. If there's no distance label,
                // the heart goes to top-right (its natural place).
                Positioned(
                  top: 6,
                  right: distanceLabel != null ? null : 6,
                  left: distanceLabel != null ? 6 : null,
                  // When the distance badge is on top-right, we shift the
                  // heart to top-left to avoid overlap. When there's no
                  // badge, top-right looks like the standard "wishlist" UI.
                  child: FavoriteHeartButton(
                    gigId: gig.id,
                    size: 18,
                  ),
                ),

                /// Bottom content
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Title
                      Text(
                        gig.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// Location
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              gig.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      /// Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _shortDate(gig.date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      /// Musician pay
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            payLabel(gig.payment, gig.paymentUnit),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
        ));
  }

  static String _shortDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }

}
