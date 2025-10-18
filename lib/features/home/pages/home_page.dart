import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../../gigs/pages/gig_detail_page.dart';
import '../../gigs/pages/gig_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Simple month formatter (no intl)
  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final mm = months[d.month - 1];
    final m2 = d.minute.toString().padLeft(2, '0');
    return '$mm ${d.day}, $h:$m2 $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Mock gigs data (DateTime + venueId to match the model)
    final upcomingGigs = [
      Gig(
        id: "1",
        title: "Bangkok Jazz Night",
        location: "Saxophone Pub",
        date: DateTime(DateTime.now().year, 9, 20, 21, 00),
        imageUrl: "https://via.placeholder.com/400x250.png?text=Jazz+Night",
        genres: const ["Jazz"],
        venueId: "demo-venue-1",
      ),
      Gig(
        id: "2",
        title: "EDM Festival",
        location: "Glow Club",
        date: DateTime(DateTime.now().year, 9, 25, 22, 00),
        imageUrl: "https://via.placeholder.com/400x250.png?text=EDM+Festival",
        genres: const ["EDM", "Dance"],
        venueId: "demo-venue-2",
      ),
    ];

    final nearbyGigs = [
      Gig(
        id: "3",
        title: "Rock Night",
        location: "Hard Rock Cafe",
        date: DateTime(DateTime.now().year, 9, 18, 21, 30),
        imageUrl: "https://via.placeholder.com/400x250.png?text=Rock+Night",
        genres: const ["Rock"],
        venueId: "demo-venue-3",
      ),
      Gig(
        id: "4",
        title: "Acoustic Evening",
        location: "Brown Sugar Bar",
        date: DateTime(DateTime.now().year, 9, 21, 20, 00),
        imageUrl: "https://via.placeholder.com/400x250.png?text=Acoustic+Evening",
        genres: const ["Acoustic"],
        venueId: "demo-venue-4",
      ),
      Gig(
        id: "5",
        title: "HipHop Battle",
        location: "Urban Stage",
        date: DateTime(DateTime.now().year, 9, 23, 22, 00),
        imageUrl: "https://via.placeholder.com/400x250.png?text=HipHop+Battle",
        genres: const ["HipHop"],
        venueId: "demo-venue-5",
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        children: [
          // 🔹 Location Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.primaryGold, size: 20),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: "Bangkok, TH",
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.darkBrown),
                      items: const [
                        DropdownMenuItem(
                            value: "Bangkok, TH", child: Text("Bangkok, TH")),
                        DropdownMenuItem(
                            value: "New York, USA", child: Text("New York, USA")),
                        DropdownMenuItem(
                            value: "London, UK", child: Text("London, UK")),
                      ],
                      onChanged: (val) {
                        // TODO: handle location change
                      },
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.darkBrown),
                ),
              ],
            ),
          ),

          // 🔹 Upcoming Gigs (horizontal, swipe)
          _sectionHeader("Upcoming Gigs", onSeeAll: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GigPage()));
          }),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: upcomingGigs.length,
              itemBuilder: (context, i) {
                final gig = upcomingGigs[i];
                return _gigCardHorizontal(context, gig, _formatDate);
              },
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Nearby Gigs (grid 2-up)
          _sectionHeader("Nearby Gigs", onSeeAll: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GigPage()));
          }),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: nearbyGigs.length,
            itemBuilder: (context, i) {
              final gig = nearbyGigs[i];
              return _gigCardGrid(context, gig, _formatDate);
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // 🔹 Section header with "See all"
  Widget _sectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppFonts.textTheme.headlineMedium),
          TextButton(
            onPressed: onSeeAll,
            child: const Text("See all",
                style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  // 🔹 Horizontal gig card
  Widget _gigCardHorizontal(
    BuildContext context,
    Gig gig,
    String Function(DateTime) formatDate,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GigDetailPage(gig: gig)),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
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
              child: Image.network(
                gig.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      color: AppColors.accentBrown),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gig.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("${gig.location} • ${formatDate(gig.date)}",
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

  // 🔹 Grid gig card
  Widget _gigCardGrid(
    BuildContext context,
    Gig gig,
    String Function(DateTime) formatDate,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GigDetailPage(gig: gig)),
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
              child: Image.network(
                gig.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      color: AppColors.accentBrown),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gig.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("${gig.location} • ${formatDate(gig.date)}",
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
