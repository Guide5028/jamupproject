import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jamup_app/features/booking/data/booking_repository.dart';
import 'package:jamup_app/features/gigs/data/gig_repository.dart';
import 'package:jamup_app/features/gigs/pages/gig_detail_page.dart';
import 'package:jamup_app/features/messages/pages/chat_page.dart';
import 'package:jamup_app/features/reviews/data/review_repository.dart';
import 'package:jamup_app/features/reviews/review_widget.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/portfolio_grid.dart';
import '../../../models/gig.dart';
import '../../../models/musician.dart';

Future<void> _share(String text) => Share.share(text);

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
            onPressed: () async {
              final m = widget.musician;
              final parts = <String>[
                '🎵 ${m.name}',
                if (m.type.isNotEmpty) m.type,
                if (m.genre.isNotEmpty) m.genre,
                if (m.location != null && m.location!.isNotEmpty)
                  '📍 ${m.location}',
                if (m.bio.isNotEmpty) '\n${m.bio}',
                if (m.priceRange != null && m.priceRange!.isNotEmpty)
                  '💰 ${m.priceRange}',
              ];
              await _share(parts.join('\n'));
            },
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
                              builder: (_) => GigDetailPage(
                                gig: Gig.fromJson(
                                    Map<String, dynamic>.from(gig)),
                              ),
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

                _buildActionButton(context),
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

  Widget _buildActionButton(BuildContext context) {
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {}
    final role = (user?.userMetadata?['role'] ?? '').toString().toLowerCase();

    if (role == 'venue') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGold,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.send, color: Colors.white, size: 18),
          label: Text(
            "Invite to Gig",
            style: AppFonts.textTheme.bodyLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showGigPickerSheet(context, user!.id),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showGigPickerSheet(BuildContext context, String venueId) async {
    final gigs = await GigRepository().fetchMyGigs(venueId);

    if (!context.mounted) return;

    if (gigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have no gigs to invite for.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GigPickerSheet(
        gigs: gigs,
        musician: widget.musician,
      ),
    );
  }
}

class _GigPickerSheet extends StatefulWidget {
  final List<Gig> gigs;
  final Musician musician;
  const _GigPickerSheet({required this.gigs, required this.musician});
  @override
  State<_GigPickerSheet> createState() => _GigPickerSheetState();
}

class _GigPickerSheetState extends State<_GigPickerSheet> {
  bool _loading = false;

  Future<void> _invite(Gig gig) async {
    setState(() => _loading = true);
    try {
      final result = await BookingRepository().inviteMusicianToGig(
        gigId: gig.id,
        musicianId: widget.musician.id,
        startTime: gig.date,
        endTime: gig.date.add(const Duration(hours: 2)),
      );
      final booking = result['booking'] as Map<String, dynamic>;
      final chatId = result['chatId'] as String;
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          bookingId: booking['id'].toString(),
          name: widget.musician.name,
          avatar: widget.musician.imageUrl,
          initialStatus: booking['status'] ?? 'pending',
          otherUserId: widget.musician.id,
          isVenue: true,
        ),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invite failed: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text("Select a Gig to Invite", style: AppFonts.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text("Inviting ${widget.musician.name}", style: AppFonts.textTheme.bodyMedium?.copyWith(color: AppColors.accentBrown)),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
          else
            ...widget.gigs.map((gig) {
              final mm = gig.date.month.toString().padLeft(2, '0');
              final dd = gig.date.day.toString().padLeft(2, '0');
              final dateStr = "${gig.date.year}-$mm-$dd";
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryGold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.music_note, color: AppColors.primaryGold),
                ),
                title: Text(gig.title, style: AppFonts.textTheme.bodyLarge),
                subtitle: Text("${gig.location} • $dateStr", style: AppFonts.textTheme.bodyMedium),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accentBrown),
                onTap: () => _invite(gig),
              );
            }),
        ],
      ),
    );
  }
}