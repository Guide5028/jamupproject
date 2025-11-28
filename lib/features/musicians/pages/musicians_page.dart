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

  String selectedFilter = "";
  bool loading = true;
  String? error;
  List<Musician> _all = [];

  final List<String> filters = const [
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
    _load();
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
    final filtered = selectedFilter.isEmpty
        ? _all
        : _all.where((m) {
            final f = selectedFilter.toLowerCase();
            return m.genre.toLowerCase() == f ||
                m.type.toLowerCase() == f;
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
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: filters.map((f) {
                final isSelected = selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGold.withOpacity(0.8),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkBrown,
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
  }
}
