import 'package:flutter/material.dart';

import 'package:jamup_app/features/booking/data/booking_repository.dart';
import 'package:jamup_app/features/gigs/pages/gig_detail_page.dart';
import 'package:jamup_app/features/reviews/data/review_repository.dart';
import 'package:jamup_app/features/reviews/review_widget.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/portfolio_grid.dart'; 
import '../../../models/musician.dart';

class MusicianDetailPage extends StatefulWidget {
  final Musician musician;

  const MusicianDetailPage({super.key, required this.musician});

  @override
  State<MusicianDetailPage> createState() => _MusicianDetailPageState();
}

class _MusicianDetailPageState extends State<MusicianDetailPage> {
  // FIX 2: _buildHeaderImage uses widget.musician not musician
  Widget _buildHeaderImage(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (widget.musician.imageUrl.isEmpty) {
      return Container(
        height: width * 0.6,
        width: double.infinity,
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.person, color: AppColors.accentBrown, size: 40),
        ),
      );
    }

    return Image.network(
      widget.musician.imageUrl,
      height: width * 0.6,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: width * 0.6,
          width: double.infinity,
          color: AppColors.background,
          child: const Center(
            child: Icon(Icons.person, color: AppColors.accentBrown, size: 40),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX 4: removed unused `width` variable from build()
    // width is only needed in _buildHeaderImage, which declares it locally

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
          // Musician Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildHeaderImage(context),
          ),

          // Musician Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags — FIX 2: widget.musician throughout
                Wrap(
                  spacing: 8,
                  children: [
                    if (widget.musician.type.isNotEmpty)
                      _buildTag(widget.musician.type),
                    if (widget.musician.genre.isNotEmpty)
                      _buildTag(widget.musician.genre),
                  ],
                ),

                const SizedBox(height: 10),

                Text(widget.musician.name,
                    style: AppFonts.textTheme.headlineLarge),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Text(
                      widget.musician.location ?? "Unknown location",
                      style: AppFonts.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    FutureBuilder(
                      future: ReviewRepository()
                          .getAverageRating(widget.musician.id),
                      builder: (context, snapshot) {
                        final rating = snapshot.data ?? 0.0;
                        return Text(
                          "${rating.toStringAsFixed(1)}/5",
                          style: AppFonts.textTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text("About", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accentBrown.withOpacity(0.15)),
                  ),
                  child: Text(
                    widget.musician.bio.isNotEmpty
                        ? widget.musician.bio
                        : "${widget.musician.name} hasn't added a bio yet.",
                    style: AppFonts.textTheme.bodyLarge,
                  ),
                ),

                const SizedBox(height: 20),

                // Profile row
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryGold,
                      child:
                          Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Musician Profile",
                            style: AppFonts.textTheme.bodyMedium),
                        Text(widget.musician.name,
                            style: AppFonts.textTheme.headlineMedium),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Text("Booking Details",
                    style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: widget.musician.performanceTypes.map((t) {
                    return _buildTag(t);
                  }).toList(),
                ),

                const SizedBox(height: 8),
                Text(
                  "Price: ${widget.musician.priceRange ?? 'Contact for pricing'}",
                  style: AppFonts.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                Text("Upcoming Shows",
                    style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),

                FutureBuilder(
                  future: BookingRepository()
                      .getUpcomingBookings(widget.musician.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text("No upcoming shows",
                          style: AppFonts.textTheme.bodyMedium);
                    }

                    return Column(
                      children: snapshot.data!.map<Widget>((b) {
                        final gig = b['gigs'];
                        final date = DateTime.parse(gig['date']);
                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GigDetailPage(gig: gig['id']),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              // FIX 3: border goes directly in BoxDecoration,
                              // NOT inside boxShadow: []
                              border: Border.all(
                                color:
                                    AppColors.accentBrown.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event,
                                    color: AppColors.primaryGold, size: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(gig['title'],
                                          style: AppFonts.textTheme.bodyLarge),
                                      const SizedBox(height: 4),
                                      Text(gig['location'],
                                          style:
                                              AppFonts.textTheme.bodyMedium),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${date.day}/${date.month}/${date.year}",
                                        style: AppFonts.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: AppColors.accentBrown),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text("Past Performances",
                    style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),

                FutureBuilder(
                  future: BookingRepository()
                      .getPastBookings(widget.musician.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text("No past performances",
                          style: AppFonts.textTheme.bodyMedium);
                    }

                    return Column(
                      children: snapshot.data!.map<Widget>((b) {
                        final gig = b['gigs'];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.music_note,
                              color: AppColors.accentBrown),
                          title: Text(gig['title'],
                              style: AppFonts.textTheme.bodyLarge),
                          subtitle: Text(
                            "${DateTime.parse(gig['date']).toLocal().toString().split(' ')[0]} • ${gig['location']}",
                            style: AppFonts.textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text("Reviews", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),
                ReviewWidget(musicianId: widget.musician.id),

                const SizedBox(height: 24),
                Text("Media", style: AppFonts.textTheme.headlineMedium),
                const SizedBox(height: 8),
                PortfolioGrid(
                  userId: widget.musician.id,
                  showDeleteButton: false,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Please select an upcoming show to book"),
                        ),
                      );
                    },
                    child: Text(
                      "Book Now",
                      style: AppFonts.textTheme.bodyLarge?.copyWith(
                          color: AppColors.background, fontWeight: FontWeight.bold),
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

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppFonts.textTheme.bodyMedium),
    );
  }
}