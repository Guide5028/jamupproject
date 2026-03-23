// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

import '../../../models/musician.dart';
import '../widgets/musician_card.dart';
import '../data/musician_repository.dart';

import '../widgets/filter_bar.dart';

class MusiciansPage extends StatefulWidget {
  const MusiciansPage({super.key});

  @override
  State<MusiciansPage> createState() => _MusiciansPageState();
}

class _MusiciansPageState extends State<MusiciansPage> {
  final _repo = MusicianRepository();
  final _searchCtrl = TextEditingController();
  String searchQuery = "";

  Set<String> selectedGenres = {};
  Set<String> selectedTypes = {};
  Set<String> selectedLocations = {};
  Set<String> selectedPrices = {};

  bool loading = true;
  String? error;
  List<Musician> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _openGenreFilter() {
    _openBottomSheet(
      title: "Genres",
      options: ["EDM", "Jazz", "HipHop", "Pop", "Rock", "Soul"],
      selectedSet: selectedGenres,
    );
  }

  void _openTypeFilter() {
    _openBottomSheet(
      title: "Type",
      options: ["Solo", "Duo", "Band"],
      selectedSet: selectedTypes,
    );
  }

  void _openLocationFilter() {
    _openBottomSheet(
      title: "Location",
      options: ["Bangkok", "Chiang Mai", "Phuket"],
      selectedSet: selectedLocations,
    );
  }

  void _openPriceFilter() {
    _openBottomSheet(
      title: "Price",
      options: ["< \$100", "\$100–\$300", "\$300+"],
      selectedSet: selectedPrices,
    );
  }

  void _openBottomSheet({
    required String title,
    required List<String> options,
    required Set<String> selectedSet,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((o) {
                  final selected = selectedSet.contains(o);
                  return ListTile(
                    title: Text(
                      o,
                      style: TextStyle(
                        color: selected ? AppColors.primaryGold : Colors.white,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check, color: AppColors.primaryGold)
                        : null,
                    onTap: () {
                      setModalState(() {
                        if (selected) {
                          selectedSet.remove(o);
                        } else {
                          selectedSet.add(o);
                        }
                      });
                      setState(() {}); // refresh page
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
      final matchesGenre = selectedGenres.isEmpty ||
          selectedGenres.any((g) =>
              m.genres.map((e) => e.toLowerCase()).contains(g.toLowerCase()));

      final matchesType =
          selectedTypes.isEmpty || selectedTypes.contains(m.type);

      // TEMP: until musician has location/price fields
      final matchesLocation = selectedLocations.isEmpty;
      final matchesPrice = selectedPrices.isEmpty;

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
              Text(error!, style: const TextStyle(color: Colors.red)),
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
            onGenreTap: _openGenreFilter,
            onTypeTap: _openTypeFilter,
            onLocationTap: _openLocationFilter,
            onPriceTap: _openPriceFilter,
            genreActive: selectedGenres.isNotEmpty,
            typeActive: selectedTypes.isNotEmpty,
            locationActive: selectedLocations.isNotEmpty,
            priceActive: selectedPrices.isNotEmpty,
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
                    selectedGenres.isNotEmpty ||
                    selectedTypes.isNotEmpty ||
                    selectedLocations.isNotEmpty ||
                    selectedPrices.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        searchQuery = "";
                        selectedGenres.clear();
                        selectedTypes.clear();
                        selectedLocations.clear();
                        selectedPrices.clear();
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

    for (final g in selectedGenres) {
      chips.add(_filterChip(g, () {
        setState(() => selectedGenres.remove(g));
      }));
    }

    for (final t in selectedTypes) {
      chips.add(_filterChip(t, () {
        setState(() => selectedTypes.remove(t));
      }));
    }

    for (final l in selectedLocations) {
      chips.add(_filterChip(l, () {
        setState(() => selectedLocations.remove(l));
      }));
    }

    for (final p in selectedPrices) {
      chips.add(_filterChip(p, () {
        setState(() => selectedPrices.remove(p));
      }));
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

  Widget _filterChip(String label, VoidCallback onRemove) {
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
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.darkBrown,
            ),
          ),
        ],
      ),
    );
  }
}
