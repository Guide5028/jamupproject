import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/musician.dart';
import '../widgets/musician_card.dart';
import '../data/musician_repository.dart';

class MusiciansPage extends StatefulWidget {
  const MusiciansPage({super.key});

  @override
  State<MusiciansPage> createState() => _MusiciansPageState();
}

class _MusiciansPageState extends State<MusiciansPage> {
  final _repo = MusicianRepository();
  late Future<List<Musician>> _future;
  String selectedFilter = "";

  // Filters stay the same
  final List<String> filters = [
    "EDM",
    "Jazz",
    "HipHop",
    "Pop",
    "Solo",
    "Duo",
    "Band",
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Musician>> _load() => _repo.fetchAll();

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Musicians"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: FutureBuilder<List<Musician>>(
        future: _future,
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
                    const Text('Failed to load musicians 😵',
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

          final all = snap.data ?? <Musician>[];

          // client-side filter by genre OR type
          final filtered = selectedFilter.isEmpty
              ? all
              : all.where((m) {
                  final f = selectedFilter.toLowerCase();
                  return m.genre.toLowerCase() == f ||
                      m.type.toLowerCase() == f;
                }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                // 🔹 Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: filters.map((f) {
                      final isSelected = selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          selectedColor:
                              AppColors.primaryGold.withOpacity(0.8),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.darkBrown,
                          ),
                          onSelected: (_) {
                            setState(() {
                              selectedFilter = isSelected ? "" : f;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // 🔹 Musicians Grid
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("No musicians yet"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
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
        },
      ),
    );
  }
}
