// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:jamup_app/core/widgets/filter_chip_tag.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

import '../../../models/musician.dart';
import '../widgets/musician_card.dart';
import '../data/musician_repository.dart';

import '../../../core/filters/filter_state.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import '../../../core/widgets/filter_bar.dart';

class MusiciansPage extends StatefulWidget {
  const MusiciansPage({super.key});

  @override
  State<MusiciansPage> createState() => _MusiciansPageState();
}

class _MusiciansPageState extends State<MusiciansPage> {
  final _repo = MusicianRepository();
  final _searchCtrl = TextEditingController();
  final filters = FilterState();
  String searchQuery = "";

  bool loading = true;
  String? error;
  List<Musician> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final filtered = _all.where((m) {
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
        body: Center(child: CircularProgressIndicator()),
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
          // 🔍 Search bar (Image 1 style)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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

          // 🎛 Filter bar (Image 1 style)
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
                options: ["< \$100", "\$100-\$300", "\$300+"],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  "${filtered.length} results",
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

          // Musicians grid
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No musicians found"))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      return MusicianCard(musician: filtered[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

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
      chips.add(
        FilterChipTag(
          label: p,
          onRemove: () {
            setState(() => filters.prices.remove(p));
          },
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
