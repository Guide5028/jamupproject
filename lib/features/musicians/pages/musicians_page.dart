import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/musician.dart';
import 'musician_detail_page.dart';
import '../widgets/musician_card.dart';

class MusiciansPage extends StatefulWidget {
  const MusiciansPage({super.key});

  @override
  State<MusiciansPage> createState() => _MusiciansPageState();
}

class _MusiciansPageState extends State<MusiciansPage> {
  String selectedFilter = "";

  // 🔹 Mock musicians data
  final List<Musician> musicians = [
    Musician(
      id: "1",
      name: "DJ Nova",
      genre: "EDM",
      type: "Solo",
      imageUrl: "https://via.placeholder.com/400x250.png?text=DJ+Nova",
    ),
    Musician(
      id: "2",
      name: "Luna Jazz Duo",
      genre: "Jazz",
      type: "Duo",
      imageUrl: "https://via.placeholder.com/400x250.png?text=Jazz+Duo",
    ),
    Musician(
      id: "3",
      name: "The HipHop Crew",
      genre: "HipHop",
      type: "Band",
      imageUrl: "https://via.placeholder.com/400x250.png?text=HipHop+Crew",
    ),
    Musician(
      id: "4",
      name: "Pop Queen",
      genre: "Pop",
      type: "Solo",
      imageUrl: "https://via.placeholder.com/400x250.png?text=Pop+Queen",
    ),
  ];

  // 🔹 Filters
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
  Widget build(BuildContext context) {
    final filtered = selectedFilter.isEmpty
        ? musicians
        : musicians.where((m) {
            return m.genre.toLowerCase() == selectedFilter.toLowerCase() ||
                m.type.toLowerCase() == selectedFilter.toLowerCase();
          }).toList();

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
          // 🔹 Filter Chips
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

          // 🔹 Musicians Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
