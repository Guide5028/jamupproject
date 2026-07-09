// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:jamup_app/core/widgets/filter_chip_tag.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

import '../../../models/musician.dart';
import '../widgets/musician_card.dart';
import '../data/musician_repository.dart';

import '../../../core/filters/filter_state.dart';
import '../../../core/services/nearby_service.dart';    // 🆕 SRS-52
import '../../../core/services/musician_favorites_service.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import '../../../core/widgets/filter_bar.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_in.dart';

class MusiciansPage extends StatefulWidget {
  const MusiciansPage({super.key});

  @override
  State<MusiciansPage> createState() => _MusiciansPageState();
}

class _MusiciansPageState extends State<MusiciansPage> {
  final _repo = MusicianRepository();
  final _nearby = NearbyService();           // 🆕 SRS-52
  final _searchCtrl = TextEditingController();
  final filters = FilterState();
  String searchQuery = "";

  bool loading = true;
  String? error;
  List<Musician> _all = [];

  bool _nearbyMode = false;
  bool _nearbyLoading = false;
  String? _nearbyError;
  List<Musician> _nearbyMusicians = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh which musicians are favorited so the hearts on each card show
    // the correct filled/outline state. Fire-and-forget — the cards listen to
    // the service and rebuild themselves once it completes.
    // ignore: unawaited_futures
    MusicianFavoritesService.instance.loadAll().catchError((_) {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Load ALL musicians ───────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final list = await _repo.fetchAll();
      setState(() {
        _all = list;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // ── Load Nearby Musicians ────────────────────────────────────────────────
  Future<void> _loadNearby() async {
    if (_nearbyMusicians.isNotEmpty) return;

    setState(() {
      _nearbyLoading = true;
      _nearbyError = null;
    });

    try {
      final rows = await _nearby.getNearbyMusicians();
      final list = rows.map((r) => Musician.fromJson(r)).toList();

      setState(() => _nearbyMusicians = list);
    } catch (e) {
      setState(() => _nearbyError = e.toString());
    } finally {
      setState(() => _nearbyLoading = false);
    }
  }

  // ── Switch between All and Nearby ───────────────────────────────────────
  void _switchMode(bool nearby) {
    setState(() => _nearbyMode = nearby);
    if (nearby) _loadNearby();
  }

  @override
  Widget build(BuildContext context) {
    // The active list depends on which tab the user has selected.
    // Both lists go through the same search + genre + type filter
    // so the filter chips work in Nearby mode too.
    final source = _nearbyMode ? _nearbyMusicians : _all;

    final filtered = source.where((m) {
      final matchesGenre = filters.genres.isEmpty ||
          filters.genres.any(
            (g) =>
                m.genres.map((e) => e.toLowerCase()).contains(g.toLowerCase()),
          );

      final matchesType =
          filters.types.isEmpty || filters.types.contains(m.type);

      // TEMP: until musician has location/price fields
      final matchesLocation = filters.locations.isEmpty;
      final matchesPrice = filters.prices.isEmpty;

      final matchesSearch = searchQuery.isEmpty ||
          m.name.toLowerCase().contains(searchQuery) ||
          m.genre.toLowerCase().contains(searchQuery);

      return matchesGenre &&
          matchesType &&
          matchesLocation &&
          matchesPrice &&
          matchesSearch;
    }).toList();

    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: SkeletonCardGrid(childAspectRatio: 0.68)),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Failed to load musicians 😵"),
              const SizedBox(height: 8),
              Text(error!,
                  style: AppFonts.textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFFE24B4A))),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Musicians"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: Column(
        children: [
          // ── All / Nearby Toggle ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: "All Musicians",
                    icon: Icons.people_outline,
                    selected: !_nearbyMode,
                    onTap: () => _switchMode(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    label: "Nearby",
                    icon: Icons.near_me_outlined,
                    selected: _nearbyMode,
                    onTap: () => _switchMode(true),
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() => searchQuery = v.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: "Search musicians, genre, type",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => searchQuery = "");
                          FocusScope.of(context).unfocus();
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),

          // 🎛 Filter bar
          FilterBar(
            onGenreTap: () {
              showFilterBottomSheet(
                context: context,
                title: "Genres",
                options: ["EDM", "Jazz", "HipHop", "Pop", "Rock", "Soul"],
                selectedSet: filters.genres,
                refresh: () => setState(() {}),
              );
            },
            onTypeTap: () {
              showFilterBottomSheet(
                context: context,
                title: "Type",
                options: ["Solo", "Duo", "Band"],
                selectedSet: filters.types,
                refresh: () => setState(() {}),
              );
            },
            onLocationTap: () {
              showFilterBottomSheet(
                context: context,
                title: "Location",
                options: ["Bangkok", "Chiang Mai", "Phuket"],
                selectedSet: filters.locations,
                refresh: () => setState(() {}),
              );
            },
            onPriceTap: () {
              showFilterBottomSheet(
                context: context,
                title: "Price",
                options: const ["< \$100", "\$100-\$300", "\$300+"],
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

          // ── Result count row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  _nearbyMode && _nearbyLoading
                      ? "Searching nearby…"
                      : "${filtered.length} results",
                  style: AppFonts.textTheme.bodyMedium,
                ),
                const Spacer(),
                if (searchQuery.isNotEmpty ||
                    filters.genres.isNotEmpty ||
                    filters.types.isNotEmpty ||
                    filters.locations.isNotEmpty ||
                    filters.prices.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        searchQuery = "";
                        filters.clear();
                      });
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text("Reset"),
                  ),
              ],
            ),
          ),

          // ── Main content area ────────────────────────────────────────────
          Expanded(
            child: _buildBody(filtered),
          ),
        ],
      ),
    );
  }

  // ── Body switches between loading / error / grid ─────────────────────────
  Widget _buildBody(List<Musician> filtered) {
    // Nearby tab: show spinner while the RPC is in-flight
    if (_nearbyMode && _nearbyLoading) {
      return const SkeletonCardGrid(childAspectRatio: 0.68);
    }

    // Nearby tab: show friendly error if GPS or RPC failed
    if (_nearbyMode && _nearbyError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off,
                size: 48, color: AppColors.accentBrown),
            const SizedBox(height: 12),
            const Text("Could not find nearby musicians"),
            const SizedBox(height: 4),
            Text(
              "Make sure location permission is granted.",
              style: AppFonts.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.accentBrown),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Force a fresh fetch by clearing the cache first
                setState(() => _nearbyMusicians = []);
                _loadNearby();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    // Empty state — shown for both All and Nearby
    if (filtered.isEmpty) {
      return EmptyState(
        icon: _nearbyMode ? Icons.near_me_disabled : Icons.person_search,
        title: _nearbyMode ? 'No musicians nearby' : 'No musicians found',
        message: _nearbyMode
            ? 'Try widening your search radius.'
            : 'Try a different genre or search term.',
      );
    }

    // Musicians Grid — each card fades + slides in, lightly staggered.
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        return FadeInUp(
          delay: Duration(milliseconds: (i % 6) * 60),
          child: MusicianCard(musician: filtered[i]),
        );
      },
    );
  }

  // ── Active filter chips row ──────────────────────────────────────────────
  Widget _activeFilters() {
    final chips = <Widget>[];

    for (final g in filters.genres) {
      chips.add(
        FilterChipTag(
          label: g,
          onRemove: () {
            setState(() => filters.genres.remove(g));
          },
        ),
      );
    }

    for (final t in filters.types) {
      chips.add(
        FilterChipTag(
          label: t,
          onRemove: () {
            setState(() => filters.types.remove(t));
          },
        ),
      );
    }

    for (final l in filters.locations) {
      chips.add(
        FilterChipTag(
          label: l,
          onRemove: () {
            setState(() => filters.locations.remove(l));
          },
        ),
      );
    }

    for (final p in filters.prices) {
      chips.add(FilterChipTag(
        label: p,
        onRemove: () => setState(() => filters.togglePrice(p)),
      ));
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

// ── Mode Toggle Button ────────────────────────────────────────────────────
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGold : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.darkBrown,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
