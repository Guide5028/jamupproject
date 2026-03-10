import 'package:flutter/material.dart';

import 'package:jamup_app/features/musicians/pages/musicians_page.dart';
import 'package:jamup_app/features/notifications/notifications_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

import '../../../models/gig.dart';

import '../../gigs/pages/gig_detail_page.dart';
import '../../gigs/pages/gig_page.dart';
import '../../gigs/data/gig_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = GigRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  late Future<List<List<Gig>>> _loadFuture;
  late final user;
  late final String? userId;
  late Future<String> _cityFuture;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();

    user = Supabase.instance.client.auth.currentUser;
    userId = user?.id;

    _loadFuture = _load();
    _cityFuture = LocationService.getCityName();
  }

  Future<List<List<Gig>>> _load() async {
    final position = await LocationService.getUserLocation();

    if (position != null) {
      _userLat = position.latitude;
      _userLng = position.longitude;
    }

    final userGenre = user?.userMetadata?['genre'];

    final results = await Future.wait([
      _repo.fetchUpcoming(limit: 10),
      if (_userLat != null)
        _repo.fetchNearbyGigs(
          userLat: _userLat!,
          userLng: _userLng!,
          radius: 5000,
        )
      else
        Future.value(<Gig>[]),
      if (userGenre != null && userGenre.toString().isNotEmpty)
        _repo.fetchAll(genre: userGenre)
      else
        Future.value(<Gig>[]),
    ]);

    return [
      results[0] as List<Gig>, // upcoming
      results[1] as List<Gig>, // nearby
      results[2] as List<Gig>, // recommended based on user's genre preference
    ];
  }

  Future<void> _refresh() async {
    setState(() => _loadFuture = _load());
    await _loadFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<List<Gig>>>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to load gigs 😵',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('${snap.error}',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Fallback empty lists if something is null
          final data = snap.data ?? [<Gig>[], <Gig>[], <Gig>[]];

          final upcomingGigs = data[0];
          final nearbyGigs = data[1];
          final recommendedGigs = data[2];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                // 🔹 Location + bell
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFB8860B), // dark gold
                        Color(0xFFD4A017), // rich gold
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Top row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              FutureBuilder<String>(
                                future: _cityFuture,
                                builder: (_, snapshot) {
                                  return Text(
                                    snapshot.data ?? "Loading location...",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsPage(),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                  right: 4,
                                  top: 4,
                                  child:
                                      StreamBuilder<List<Map<String, dynamic>>>(
                                    stream: Supabase.instance.client
                                        .from('notifications')
                                        .stream(primaryKey: ['id']).map(
                                            (data) => data
                                                .where((n) =>
                                                    n['user_id'] == userId &&
                                                    n['is_read'] == false)
                                                .toList()),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData)
                                        return const SizedBox();

                                      final unread = snapshot.data!.length;

                                      if (unread == 0) return const SizedBox();

                                      return Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          unread > 9 ? '9+' : '$unread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  )),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (value) {
                            if (value.trim().isEmpty) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GigPage(searchQuery: value.trim()),
                              ),
                            );
                          },
                          decoration: const InputDecoration(
                            hintText: "Search gigs...",
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// Hero Text
                      const Text(
                        "Your Stage,\nOne Tap Away 🎸",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Discover gigs that match your sound.",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Explore Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1F5F5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GigPage()),
                          );
                        },
                        child: const Text("Explore"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Explore",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.8,
                    children: [
                      _categoryCard(
                        icon: Icons.event_outlined,
                        title: "Upcoming",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GigPage()),
                          );
                        },
                      ),
                      _categoryCard(
                        icon: Icons.location_on_outlined,
                        title: "Nearby",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GigPage()),
                          );
                        },
                      ),
                      _categoryCard(
                        icon: Icons.auto_awesome_outlined,
                        title: "Recommended",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GigPage()),
                          );
                        },
                      ),
                      _categoryCard(
                        icon: Icons.people_outline,
                        title: "Musicians",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MusiciansPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Recommended for users
                _sectionHeader(context, "Recommended for You", onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GigPage()),
                  );
                }),

                SizedBox(
                  height: 300,
                  child: recommendedGigs.isEmpty
                      ? const Center(child: Text("No recommendations yet"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: recommendedGigs.length,
                          itemBuilder: (_, i) =>
                              _gigCardHorizontal(context, recommendedGigs[i]),
                        ),
                ),
                
                // 🔹 Upcoming
                _sectionHeader(context, "Upcoming Gigs", onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GigPage()),
                  );
                }),
                SizedBox(
                  height: 300,
                  child: upcomingGigs.isEmpty
                      ? const Center(child: Text("No upcoming gigs"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: upcomingGigs.length,
                          itemBuilder: (_, i) =>
                              _gigCardHorizontal(context, upcomingGigs[i]),
                        ),
                ),

                const SizedBox(height: 30),

                // 🔹 Nearby
                _sectionHeader(context, "Nearby Gigs", onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GigPage()),
                  );
                }),
                nearbyGigs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text("No nearby gigs yet"),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: nearbyGigs.length,
                        itemBuilder: (_, i) =>
                            _gigCardGrid(context, nearbyGigs[i]),
                      ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================
  //  UI helpers
  // ==========================

  Widget _sectionHeader(BuildContext context, String title,
      {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppFonts.textTheme.headlineMedium),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              "See all",
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gigCardHorizontal(BuildContext context, Gig gig) {
    final hasImage = gig.imageUrl.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GigDetailPage(gig: gig)),
      ),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 18),
        child: Card(
          elevation: 6,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE SECTION
              Stack(
                children: [
                  hasImage
                      ? Image.network(gig.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        }, errorBuilder: (_, __, ___) {
                          return _placeholderImage(160);
                        })
                      : _placeholderImage(160),

                  /// Category badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        gig.genres.isNotEmpty ? gig.genres.first : "Music",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  /// Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),

              /// CONTENT
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gig.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.accentBrown),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gig.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accentBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shortDate(gig.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accentBrown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "฿ ${gig.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryGold,
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

  Widget _gigCardGrid(BuildContext context, Gig gig) {
    final hasImage = gig.imageUrl.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GigDetailPage(gig: gig)),
      ),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE WITH OVERLAY
            Stack(
              children: [
                hasImage
                    ? Image.network(
                        gig.imageUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      )
                    : _placeholderImage(130),

                /// Gradient overlay (professional touch)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// Title on image
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Text(
                    gig.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                /// Small favorite icon
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
              ],
            ),

            /// CONTENT SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.accentBrown),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gig.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accentBrown,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// Date
                  Text(
                    _shortDate(gig.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accentBrown,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// Price highlight
                  Text(
                    "฿ ${gig.price.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
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

  // simple gray note placeholder to avoid red broken-image bar
  Widget _placeholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.music_note, color: AppColors.accentBrown),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.accentBrown,
                  ),
                ],
              ),
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
