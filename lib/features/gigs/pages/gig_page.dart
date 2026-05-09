import 'package:flutter/material.dart';
import 'package:jamup_app/core/services/location_service.dart';
import 'package:provider/provider.dart';

import '../../../core/filters/filter_state.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import '../../../core/widgets/filter_chip_tag.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../controllers/gig_controller.dart';
import '../data/gig_repository.dart';
import '../widgets/gig_card.dart';

import '../../../core/widgets/filter_bar.dart';

class GigPage extends StatefulWidget {
  final String? searchQuery;

  const GigPage({super.key, this.searchQuery});

  @override
  State<GigPage> createState() => _GigPageState();
}

class _GigPageState extends State<GigPage> {
  final _searchCtrl = TextEditingController();

  // ── Location bottom sheet ─────────────────────────────────────────────
  // Shows TWO sections:
  //   1) "📍 Near me" — toggles the GPS nearby mode (loads via RPC + sorts by distance)
  //   2) City text chips — populates FilterState.locations for a contains-match filter
  //      on the already-loaded gig list. Both can be active at once.
  void _showLocationPicker(
    BuildContext context,
    GigController ctrl,
    FilterState filters,
  ) {
    const cities = [
      'Bangkok',
      'Chiang Mai',
      'Phuket',
      'Pattaya',
      'Chiang Rai',
      'Hua Hin',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (sheetCtx, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // ── GPS nearby toggle ──────────────────────────────
                ListTile(
                  leading: Icon(
                    Icons.near_me,
                    color: ctrl.isNearbyMode
                        ? AppColors.primaryGold
                        : Colors.white54,
                  ),
                  title: Text(
                    ctrl.isNearbyMode
                        ? 'Near me — ${ctrl.radiusKm.toStringAsFixed(0)} km ✓'
                        : 'Near me (use GPS)',
                    style: TextStyle(
                      color: ctrl.isNearbyMode
                          ? AppColors.primaryGold
                          : Colors.white,
                      fontWeight: ctrl.isNearbyMode
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: ctrl.isNearbyMode
                      ? const Icon(Icons.check, color: AppColors.primaryGold)
                      : null,
                  onTap: () async {
                    if (ctrl.isNearbyMode) {
                      ctrl.loadAll();
                      ctrl.setSort(GigSort.oldest);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    } else {
                      final pos = await LocationService.getUserLocation();
                      if (pos == null) {
                        if (sheetCtx.mounted) {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Could not get location. Enable GPS.'),
                            ),
                          );
                        }
                        return;
                      }
                      ctrl.loadNearby(
                        lat: pos.latitude,
                        lng: pos.longitude,
                        radiusKm: ctrl.radiusKm,
                      );
                      ctrl.setSort(GigSort.distance);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    }
                  },
                ),

                const Divider(color: Colors.white24, height: 1),

                // ── City text filters ──────────────────────────────
                ...cities.map((city) {
                  final selected = filters.locations.contains(city);
                  return ListTile(
                    leading: const Icon(Icons.location_city,
                        color: Colors.white54, size: 20),
                    title: Text(
                      city,
                      style: TextStyle(
                        color:
                            selected ? AppColors.primaryGold : Colors.white,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check,
                            color: AppColors.primaryGold)
                        : null,
                    onTap: () {
                      setModal(() => filters.toggleLocation(city));
                      // Sync immediately so the filter updates without
                      // waiting for the next frame's addPostFrameCallback.
                      ctrl.setLocationFilters(Set.from(filters.locations));
                    },
                  );
                }),

                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  void _showRadiusPicker(BuildContext context, GigController ctrl) {
    double tempRadius = ctrl.radiusKm;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Search radius', style: AppFonts.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                '${tempRadius.toStringAsFixed(0)} km',
                style: AppFonts.textTheme.headlineLarge
                    ?.copyWith(color: AppColors.primaryGold, fontSize: 32),
              ),
              Slider(
                value: tempRadius,
                min: 5,
                max: 100,
                divisions: 19,
                activeColor: AppColors.primaryGold,
                inactiveColor: AppColors.accentBrown.withOpacity(0.3),
                onChanged: (v) => setModal(() => tempRadius = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5 km', style: AppFonts.textTheme.bodyMedium),
                  Text('100 km', style: AppFonts.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    ctrl.setNearbyRadius(tempRadius);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final ctrl = GigController(GigRepository())..loadGigs();

            if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
              ctrl.setSearchQuery(widget.searchQuery!);
            }

            return ctrl;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => FilterState(),
        ),
      ],
      child: Consumer<GigController>(
        builder: (context, ctrl, _) {
          final filters = context.watch<FilterState>();

          // ⚠️ Why addPostFrameCallback?
          // We're INSIDE a build() here. If we call setGenreFilters()
          // directly, it triggers notifyListeners() which schedules a
          // rebuild — but we're already building, so Flutter throws
          // "setState() called during build".
          //
          // addPostFrameCallback queues the call to run AFTER this
          // current frame finishes painting. By then Flutter is idle
          // and safe to accept new state changes.
          //
          // Together with the setEquals() guard inside setGenreFilters,
          // this also prevents an infinite rebuild loop: the second
          // call sees no change and returns early.
          // Push ALL active filter sets into the controller AFTER the
          // frame is done painting. Each setX() short-circuits if the
          // value is unchanged (setEquals guard inside the controller),
          // so this is cheap on every rebuild.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ctrl.setGenreFilters(filters.genres);
            ctrl.setTypeFilters(filters.types);
            ctrl.setLocationFilters(filters.locations);
            ctrl.setPriceFilters(filters.prices);
          });

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text("Gigs"),
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.darkBrown),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  /// SEARCH
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: ctrl.setSearchQuery,
                        decoration: const InputDecoration(
                          hintText: "Search gigs...",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  /// FILTER BAR
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
                        refresh: () {
                          context
                              .read<GigController>()
                              .setGenreFilters(filters.genres);
                        },
                      );
                    },
                    onTypeTap: () {
                      // Same role list as Create Gig + Home page. Selecting
                      // a role here narrows results to gigs whose
                      // role_needed exactly matches.
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
                        refresh: () {
                          context
                              .read<GigController>()
                              .setTypeFilters(filters.types);
                        },
                      );
                    },
                    onLocationTap: () =>
                        _showLocationPicker(context, ctrl, filters),
                    onPriceTap: () {
                      // Bucket labels MUST stay in sync with the parser
                      // in GigController._matchesPriceBucket. The "฿"
                      // is stripped by the parser, so it's purely visual.
                      showFilterBottomSheet(
                        context: context,
                        title: "Price",
                        options: const [
                          "<฿3000",
                          "฿3000-฿10000",
                          "฿10000+",
                        ],
                        selectedSet: filters.prices,
                        refresh: () {
                          context
                              .read<GigController>()
                              .setPriceFilters(filters.prices);
                        },
                      );
                    },
                    genreActive: filters.genreActive,
                    typeActive: filters.typeActive,
                    // Highlight if GPS nearby OR any city text filter is active
                    locationActive:
                        ctrl.isNearbyMode || filters.locationActive,
                    priceActive: filters.priceActive,
                  ),
                  if (ctrl.isNearbyMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me,
                              size: 14, color: AppColors.primaryGold),
                          const SizedBox(width: 6),
                          Text(
                            'Within ${ctrl.radiusKm.toStringAsFixed(0)} km',
                            style: AppFonts.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryGold, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showRadiusPicker(context, ctrl),
                            child: Text(
                              'Change',
                              style: AppFonts.textTheme.bodyMedium?.copyWith(
                                color: AppColors.accentBrown,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  /// ACTIVE FILTER CHIPS
                  Builder(
                    builder: (context) => _activeFilters(context),
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),

                  /// RESULTS
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        if (ctrl.loading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (ctrl.filtered.isEmpty) {
                          return const Center(
                            child: Text("No gigs match your search"),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: ctrl.filtered.length,
                          itemBuilder: (_, i) {
                            final gig = ctrl.filtered[i];
                            return GigCard(
                              gig: gig,
                              distanceLabel:
                                  ctrl.isNearbyMode && gig.distance != null
                                      ? '${gig.distance!.toStringAsFixed(1)} km'
                                      : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _activeFilters(BuildContext context) {
    final filters = context.watch<FilterState>();
    final ctrl = context.read<GigController>();

    final chips = <Widget>[];

    // Genre chips
    for (final g in filters.genres) {
      chips.add(FilterChipTag(label: g, onRemove: () => filters.removeGenre(g)));
    }

    // Type chips
    for (final t in filters.types) {
      chips.add(FilterChipTag(label: t, onRemove: () => filters.toggleType(t)));
    }

    // Location city chips (text filter — separate from GPS nearby mode)
    for (final l in filters.locations) {
      chips.add(FilterChipTag(
        label: l,
        onRemove: () {
          filters.toggleLocation(l);
          // Sync removal immediately so filtered list updates right away.
          ctrl.setLocationFilters(Set.from(filters.locations));
        },
      ));
    }

    // Price chips
    for (final p in filters.prices) {
      chips.add(FilterChipTag(label: p, onRemove: () => filters.togglePrice(p)));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }
}
