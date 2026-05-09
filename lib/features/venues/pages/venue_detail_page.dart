// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:jamup_app/features/gigs/pages/gig_detail_page.dart';
import 'package:jamup_app/features/reviews/data/review_repository.dart';
import 'package:jamup_app/features/reviews/review_widget.dart';
import 'package:jamup_app/features/venues/data/venue_repository.dart';
import 'package:jamup_app/models/gig.dart';
import 'package:jamup_app/models/venue.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/portfolio_grid.dart';

class VenueDetailPage extends StatefulWidget {
  final String venueId;
  final VenueRepository? venueRepo;
  final ReviewRepository? reviewRepo;

  const VenueDetailPage({super.key, required this.venueId, this.venueRepo, this.reviewRepo});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  late final VenueRepository _repo;
  late final ReviewRepository _reviewRepo;

  late Future<_PageData> _data;

  @override
  void initState() {
    super.initState();
    _repo = widget.venueRepo ?? VenueRepository();
    _reviewRepo = widget.reviewRepo ?? ReviewRepository();
    _data = _load();
  }

  Future<_PageData> _load() async {
    final results = await Future.wait([
      _repo.fetchVenue(widget.venueId),
      _repo.fetchGigsHostedCount(widget.venueId),
      _repo.fetchUpcomingGigs(widget.venueId),
      _repo.fetchPastGigs(widget.venueId),
      _reviewRepo.getAverageRating(widget.venueId),
      _reviewRepo.getReviews(widget.venueId),
    ]);

    return _PageData(
      venue: results[0] as Venue?,
      gigsHosted: results[1] as int,
      upcomingGigs: results[2] as List<Gig>,
      pastGigs: results[3] as List<Gig>,
      avgRating: results[4] as double,
      reviews: results[5] as List<Map<String, dynamic>>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_PageData>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data?.venue == null) {
            return _ErrorView(onRetry: () => setState(() => _data = _load()));
          }
          return _Body(data: snap.data!, venueId: widget.venueId);
        },
      ),
    );
  }
}

// ─── Main body ───────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final _PageData data;
  final String venueId;

  const _Body({required this.data, required this.venueId});

  @override
  Widget build(BuildContext context) {
    final venue = data.venue!;
    final width = MediaQuery.of(context).size.width;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: width * 0.58,
          pinned: true,
          backgroundColor: AppColors.background,
          iconTheme: const IconThemeData(color: AppColors.darkBrown),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.darkBrown),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _CoverImage(url: venue.imageUrl),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Name
              Text(venue.name, style: AppFonts.textTheme.headlineLarge),
              const SizedBox(height: 6),

              // Location
              if ((venue.location ?? '').isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 15, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(venue.location!,
                          style: AppFonts.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // ── Trust stats ──
              _TrustCard(
                avgRating: data.avgRating,
                reviewCount: data.reviews.length,
                gigsHosted: data.gigsHosted,
                memberSince: venue.createdAt,
              ),

              const SizedBox(height: 20),

              // Genre tags
              if (venue.genres.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: venue.genres.map((g) => _Tag(g)).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // About
              Text('About', style: AppFonts.textTheme.headlineMedium),
              const SizedBox(height: 8),
              _Card(
                child: Text(
                  venue.bio.isNotEmpty
                      ? venue.bio
                      : '${venue.name} hasn\'t added a description yet.',
                  style: AppFonts.textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: 24),

              // Open gigs
              _SectionHeader(
                title: 'Open Gigs',
                subtitle: 'Tap a gig to apply',
              ),
              const SizedBox(height: 8),
              if (data.upcomingGigs.isEmpty)
                _EmptyHint(icon: Icons.event_available,
                    text: 'No upcoming gigs right now')
              else
                ...data.upcomingGigs.map((g) => _GigRow(gig: g, upcoming: true)),

              const SizedBox(height: 24),

              // Past events
              _SectionHeader(
                title: 'Past Events',
                subtitle: '${data.pastGigs.length} events hosted',
              ),
              const SizedBox(height: 8),
              if (data.pastGigs.isEmpty)
                _EmptyHint(icon: Icons.history, text: 'No past events yet')
              else
                ...data.pastGigs.map((g) => _GigRow(gig: g, upcoming: false)),

              const SizedBox(height: 24),

              // Reviews
              Text('Reviews from Musicians',
                  style: AppFonts.textTheme.headlineMedium),
              const SizedBox(height: 6),
              if (data.reviews.isNotEmpty) ...[
                _StarBar(avg: data.avgRating, count: data.reviews.length),
                const SizedBox(height: 8),
              ],
              ReviewWidget(musicianId: venueId),

              const SizedBox(height: 24),

              // Photos
              Text('Venue Photos', style: AppFonts.textTheme.headlineMedium),
              const SizedBox(height: 8),
              PortfolioGrid(userId: venueId, showDeleteButton: false),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.accentBrown.withOpacity(0.12),
        child: const Center(
            child: Icon(Icons.store, size: 64, color: AppColors.accentBrown)),
      );
    }
    return Image.network(url, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
              color: AppColors.accentBrown.withOpacity(0.12),
              child: const Center(
                  child: Icon(Icons.store,
                      size: 64, color: AppColors.accentBrown)),
            ));
  }
}

class _TrustCard extends StatelessWidget {
  final double avgRating;
  final int reviewCount;
  final int gigsHosted;
  final DateTime? memberSince;

  const _TrustCard({
    required this.avgRating,
    required this.reviewCount,
    required this.gigsHosted,
    required this.memberSince,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            value: avgRating == 0 ? '—' : avgRating.toStringAsFixed(1),
            label: '$reviewCount review${reviewCount == 1 ? '' : 's'}',
          ),
          _VDivider(),
          _Stat(
            icon: Icons.event_note,
            iconColor: AppColors.primaryGold,
            value: '$gigsHosted',
            label: 'gigs hosted',
          ),
          _VDivider(),
          _Stat(
            icon: Icons.calendar_today,
            iconColor: AppColors.accentBrown,
            value: memberSince != null ? '${memberSince!.year}' : '—',
            label: 'member since',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown)),
        Text(label,
            style: AppFonts.textTheme.bodyMedium?.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 40,
      width: 1,
      color: AppColors.accentBrown.withOpacity(0.2));
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: AppFonts.textTheme.bodyMedium?.copyWith(fontSize: 12)),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accentBrown.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppFonts.textTheme.headlineMedium),
        Text(subtitle,
            style: AppFonts.textTheme.bodyMedium
                ?.copyWith(color: AppColors.accentBrown, fontSize: 12)),
      ],
    );
  }
}

class _GigRow extends StatelessWidget {
  final Gig gig;
  final bool upcoming;
  const _GigRow({required this.gig, required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final d = gig.date;
    final dateStr = '${d.day}/${d.month}/${d.year}';

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GigDetailPage(gig: gig))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.accentBrown.withOpacity(0.12)),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 4,
                offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: upcoming
                    ? AppColors.primaryGold.withOpacity(0.15)
                    : AppColors.accentBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                upcoming ? Icons.event_available : Icons.event,
                color: upcoming
                    ? AppColors.primaryGold
                    : AppColors.accentBrown,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gig.title, style: AppFonts.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: AppFonts.textTheme.bodyMedium
                          ?.copyWith(
                              color: AppColors.accentBrown, fontSize: 12)),
                  if (gig.roleNeeded.isNotEmpty)
                    Text('Looking for: ${gig.roleNeeded}',
                        style: AppFonts.textTheme.bodyMedium
                            ?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            if (upcoming)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Apply',
                    style: AppFonts.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              )
            else
              const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StarBar extends StatelessWidget {
  final double avg;
  final int count;
  const _StarBar({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    final stars = avg.round().clamp(0, 5);
    return Row(
      children: [
        ...List.generate(
            5,
            (i) => Icon(
                  i < stars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 20,
                )),
        const SizedBox(width: 8),
        Text('${avg.toStringAsFixed(1)} / 5  ($count)',
            style: AppFonts.textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accentBrown),
          const SizedBox(width: 8),
          Text(text,
              style: AppFonts.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.accentBrown)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: AppColors.accentBrown),
          const SizedBox(height: 12),
          const Text('Could not load venue profile'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final Venue? venue;
  final int gigsHosted;
  final List<Gig> upcomingGigs;
  final List<Gig> pastGigs;
  final double avgRating;
  final List<Map<String, dynamic>> reviews;

  const _PageData({
    required this.venue,
    required this.gigsHosted,
    required this.upcomingGigs,
    required this.pastGigs,
    required this.avgRating,
    required this.reviews,
  });
}
