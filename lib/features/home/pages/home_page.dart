import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/location_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

import '../../../models/gig.dart';

import '../../gigs/pages/gig_detail_page.dart';
import '../../gigs/pages/gig_page.dart';
import '../../gigs/data/gig_repository.dart';

import '../../../core/filters/filter_state.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import '../../../core/widgets/filter_bar.dart';

import 'package:jamup_app/features/notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = GigRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  final filters = FilterState();
  late Future<List<List<Gig>>> _loadFuture;
  late final user;
  late final String? userId;
  late Future<String> _cityFuture;
  double? _userLat;
  double? _userLng;

  String searchQuery = "";

  @override
  void initState() {
    super.initState();

    user = Supabase.instance.client.auth.currentUser;
    userId = user?.id;

    _loadFuture = _load();
    _cityFuture = LocationService.getCityName();
  }

  // (Removed `_openBottomSheet` — it was a multi-select filter helper that
  // nothing currently calls. Keeping it around as dead code was misleading;
  // when the filter UI gets re-introduced, build it fresh from the new spec.)

  Future<List<List<Gig>>> _load() async {
    // Teaching note: these print() calls are DIAGNOSTIC. When the home
    // page looks stuck, we can read the VS Code terminal and see exactly
    // which await is the slow one. Remove or comment out once things work.
    print('[HomePage._load] started');

    final position = await LocationService.getUserLocation();
    print('[HomePage._load] got position: $position');

    if (position != null) {
      _userLat = position.latitude;
      _userLng = position.longitude;
    }

    final userGenre = user?.userMetadata?['genre'];

    print('[HomePage._load] fetching gigs (userLat=$_userLat, '
        'userGenre=$userGenre)');

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

    print('[HomePage._load] done. upcoming=${results[0].length}, '
        'nearby=${results[1].length}, recommended=${results[2].length}');

    return [
      results[0],
      results[1],
      results[2],
    ];
  }

  Future<void> _refresh() async {
    setState(() => _loadFuture = _load());
    await _loadFuture;
  }

  // Bucket logic mirrors the controller's `_matchesPriceBucket`. We keep
  // the parser local to this page (instead of importing it) so the home
  // page is self-contained — but the rules MUST stay in sync. If you
  // change one, change both.
  bool _matchesPriceBucket(double price, String bucket) {
    final clean = bucket.replaceAll('฿', '').replaceAll(',', '').trim();
    if (clean.startsWith('<')) {
      final upper = double.tryParse(clean.substring(1).trim());
      return upper != null && price < upper;
    }
    if (clean.endsWith('+')) {
      final lower =
          double.tryParse(clean.substring(0, clean.length - 1).trim());
      return lower != null && price >= lower;
    }
    if (clean.contains('-')) {
      final parts = clean.split('-');
      final lower = double.tryParse(parts[0].trim());
      final upper = double.tryParse(parts[1].trim());
      return lower != null &&
          upper != null &&
          price >= lower &&
          price <= upper;
    }
    return false;
  }

  List<Gig> filterGigs(List<Gig> gigs) {
    return gigs.where((g) {
      // 1) Genre — already worked. Case-insensitive any-match.
      final matchesGenre = filters.genres.isEmpty ||
          filters.genres.any((genre) => g.genres
              .map((e) => e.toLowerCase())
              .contains(genre.toLowerCase()));

      // 2) Type (role_needed) — the bottom sheet now lists the same role
      //    options as the Create-Gig form, so values should match exactly.
      final matchesType = filters.types.isEmpty ||
          filters.types
              .map((t) => t.toLowerCase())
              .contains(g.roleNeeded.toLowerCase());

      // 3) Location — case-insensitive contains. Picking "Bangkok"
      //    matches "Saxophone Pub, Bangkok" or just "Bangkok".
      final matchesLocation = filters.locations.isEmpty ||
          filters.locations
              .any((s) => g.location.toLowerCase().contains(s.toLowerCase()));

      // 4) Price bucket — only run if `payment` is set. Gigs without a
      //    payment value are excluded from price-filtered results, which
      //    is the safe choice (don't pretend a null is in any bucket).
      final matchesPrice = filters.prices.isEmpty ||
          (g.payment != null &&
              filters.prices
                  .any((b) => _matchesPriceBucket(g.payment!, b)));

      // 5) Free-text search across title + location.
      final matchesSearch = searchQuery.isEmpty ||
          g.title.toLowerCase().contains(searchQuery) ||
          g.location.toLowerCase().contains(searchQuery);

      return matchesGenre &&
          matchesType &&
          matchesLocation &&
          matchesPrice &&
          matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<List<Gig>>>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 100),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  },
                )
              ],
            );
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
          final baseList =
              recommendedGigs.isNotEmpty ? recommendedGigs : upcomingGigs;

          final filteredRecommended = filterGigs(baseList);
          final filteredUpcoming = filterGigs(upcomingGigs);
          final filteredNearby = filterGigs(nearbyGigs);

          return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // 🔹 Location + bell
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFB8860B),
                            Color(0xFFD4A017),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
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
                                          builder: (_) =>
                                              const NotificationsPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                      right: 4,
                                      top: 4,
                                      child: StreamBuilder<
                                          List<Map<String, dynamic>>>(
                                        stream: Supabase.instance.client
                                            .from('notifications')
                                            .stream(primaryKey: ['id']).map(
                                                (data) => data
                                                    .where((n) =>
                                                        n['user_id'] ==
                                                            userId &&
                                                        n['is_read'] == false)
                                                    .toList()),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData)
                                            return const SizedBox();

                                          final unread = snapshot.data!.length;

                                          if (unread == 0)
                                            return const SizedBox();

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

                          _searchBar(),

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
                            child: const Text("Explore"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const GigPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    FilterBar(
                      onGenreTap: () {
                        showFilterBottomSheet(
                          context: context,
                          title: "Genres",
                          options: [
                            "EDM",
                            "Jazz",
                            "HipHop",
                            "Pop",
                            "Rock",
                            "Soul"
                          ],
                          selectedSet: filters.genres,
                          refresh: () => setState(() {}),
                        );
                      },
                      onTypeTap: () {
                        // "Type" on a GIG = which role the venue needs.
                        // Keep this list in sync with create_gig_page.dart's
                        // _roleNeeded dropdown so values round-trip cleanly.
                        showFilterBottomSheet(
                          context: context,
                          title: "Type",
                          options: const [
                            "Singer",
                            "Guitarist",
                            "Pianist",
                            "Drummer",
                            "DJ",
                            "Band",
                          ],
                          selectedSet: filters.types,
                          refresh: () => setState(() {}),
                        );
                      },
                      onLocationTap: () {
                        showFilterBottomSheet(
                          context: context,
                          title: "Location",
                          options: ["Bangkok", "Chiang Mai"],
                          selectedSet: filters.locations,
                          refresh: () => setState(() {}),
                        );
                      },
                      onPriceTap: () {
                        showFilterBottomSheet(
                          context: context,
                          title: "Price",
                          options: ["< ฿3000", "฿3000-฿10000", "฿10000+"],
                          selectedSet: filters.prices,
                          refresh: () => setState(() {}),
                        );
                      },
                      genreActive: filters.genreActive,
                      typeActive: filters.typeActive,
                      locationActive: filters.locationActive,
                      priceActive: filters.priceActive,
                    ),

                    _activeFilters(),

                    const SizedBox(height: 30),

                    // 🔹 Recommended for users
                    _sectionHeader(context, "Recommended for You",
                        onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GigPage()),
                      );
                    }),

                    SizedBox(
                      height: 300,
                      child: filteredRecommended.isEmpty
                          ? const Center(child: Text("No gigs available"))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filteredRecommended.length,
                              itemBuilder: (_, i) => _gigCardHorizontal(
                                  context, filteredRecommended[i]),
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
                      child: filteredUpcoming.isEmpty
                          ? const Center(child: Text("No upcoming gigs"))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filteredUpcoming.length,
                              itemBuilder: (_, i) => _gigCardHorizontal(
                                  context, filteredUpcoming[i]),
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

                    filteredNearby.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text("No nearby gigs")),
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
                            itemCount: filteredNearby.length,
                            itemBuilder: (_, i) =>
                                _gigCardGrid(context, filteredNearby[i]),
                          ),
                  ]));
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

  Widget _activeFilters() {
    final allFilters = [
      ...filters.genres,
      ...filters.types,
      ...filters.locations,
      ...filters.prices,
    ];

    if (allFilters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allFilters.map((f) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryGold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      filters.genres.remove(f);
                      filters.types.remove(f);
                      filters.locations.remove(f);
                      filters.prices.remove(f);
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _searchBar({String hint = "Search gigs..."}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchCtrl,
        onSubmitted: (value) {
          if (value.trim().isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GigPage(searchQuery: value.trim()),
            ),
          );
        },
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase().trim();
          });
        },
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  static String _shortDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }
}
