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

          ctrl.setGenreFilters(filters.genres);

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
                    onTypeTap: () {},
                    onLocationTap: () async {
                      if (ctrl.isNearbyMode) {
                        ctrl.loadAll(); // turn off → back to all gigs
                        ctrl.setSort(
                            GigSort.dateAsc); // reset sort back to date
                      } else {
                        final pos = await LocationService.getUserLocation();
                        if (pos == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Could not get location. Enable GPS.')),
                            );
                          }
                          return;
                        }
                        ctrl.loadNearby(
                            lat: pos.latitude,
                            lng: pos.longitude,
                            radiusKm: ctrl.radiusKm);
                        ctrl.setSort(GigSort
                            .distance); // sort closest first automatically
                      }
                    },
                    onPriceTap: () {},
                    genreActive: filters.genreActive,
                    typeActive: filters.typeActive,
                    locationActive: ctrl.isNearbyMode,
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

    final chips = <Widget>[];

    for (final g in filters.genres) {
      chips.add(
        FilterChipTag(
          label: g,
          onRemove: () => filters.removeGenre(g),
        ),
      );
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
