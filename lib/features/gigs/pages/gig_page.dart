import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../controllers/gig_controller.dart';
import '../data/gig_repository.dart';
import '../widgets/gig_card.dart';

class GigPage extends StatefulWidget {
  final String? searchQuery;

  const GigPage({super.key, this.searchQuery});

  @override
  State<GigPage> createState() => _GigPageState();
}

class _GigPageState extends State<GigPage> {
  final _searchCtrl = TextEditingController();

  static const _filters = [
    "All",
    "Nearby",
    "Jazz",
    "EDM",
    "Rock",
    "Acoustic",
  ];
  static const _sortItems = {
    "Date ↑": GigSort.dateAsc,
    "Date ↓": GigSort.dateDesc,
    "Nearest": GigSort.distance,
    "Title A–Z": GigSort.titleAz,
    "Title Z–A": GigSort.titleZa,
    "Location A–Z": GigSort.locationAz,
    "Location Z–A": GigSort.locationZa,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final ctrl = GigController(GigRepository())..loadGigs();

        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          ctrl.setSearchQuery(widget.searchQuery!);
        }

        return ctrl;
      },
      child: Consumer<GigController>(
        builder: (context, ctrl, _) {
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
                        ),
                      ),
                    ),
                  ),
                  // 🔹 Filters row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Row(
                      children: _filters.map((f) {
                        final selected = (f == "All")
                            ? ctrl.selectedFilter.isEmpty
                            : ctrl.selectedFilter == f;

                        return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: selected,
                              onSelected: (_) {
                                if (f == "Nearby") {
                                  _showRadiusSheet(context, ctrl);
                                } else if (f == "All") {
                                  ctrl.toggleFilter("");
                                } else {
                                  ctrl.toggleFilter(f);
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.primaryGold
                                      : Colors.grey.shade300,
                                ),
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primaryGold,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ));
                      }).toList(),
                    ),
                  ),

                  // 🎸 Gig cards grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          "${ctrl.filtered.length} gigs",
                          style: AppFonts.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<GigSort>(
                            value: ctrl.sort,
                            icon: const Icon(Icons.sort, size: 20),
                            onChanged: (v) =>
                                v != null ? ctrl.setSort(v) : null,
                            items: _sortItems.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.value,
                                child: Text(e.key),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        if (ctrl.loading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (ctrl.error != null) {
                          return Center(child: Text("Error: ${ctrl.error}"));
                        }

                        if (ctrl.filtered.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 90),
                              const Icon(Icons.search_off,
                                  size: 52, color: AppColors.accentBrown),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  "No gigs match your search",
                                  style: AppFonts.textTheme.headlineMedium,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  "Try different keywords or clear filters.",
                                  style: AppFonts.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    ctrl.clearSearch();
                                    ctrl.toggleFilter("");
                                  },
                                  icon: const Icon(Icons.filter_alt_off),
                                  label: const Text("Clear filters"),
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  ctrl.isNearbyMode
                                      ? "Gigs Near You"
                                      : "Discover Gigs",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                                child: RefreshIndicator(
                              onRefresh: () {
                                if (ctrl.isNearbyMode && ctrl.userLat != null) {
                                  return ctrl.loadNearby(
                                    lat: ctrl.userLat!,
                                    lng: ctrl.userLng!,
                                  );
                                } else {
                                  return ctrl.loadAll();
                                }
                              },
                              child: GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: ctrl.filtered.length,
                                itemBuilder: (context, i) {
                                  return GigCard(gig: ctrl.filtered[i]);
                                },
                              ),
                            )),
                          ],
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

  void _showRadiusSheet(BuildContext context, GigController ctrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [5, 10, 20].map((km) {
              return ListTile(
                title: Text("Within $km km"),
                onTap: () async {
                  Navigator.pop(context);
                  final pos = await Geolocator.getCurrentPosition();
                  await ctrl.loadNearby(
                    lat: pos.latitude,
                    lng: pos.longitude,
                    radiusKm: km.toDouble(),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
