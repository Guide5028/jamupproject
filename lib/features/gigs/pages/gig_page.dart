import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/gig.dart';
import '../widgets/gig_card.dart';

class GigPage extends StatefulWidget {
  const GigPage({super.key});

  @override
  State<GigPage> createState() => _GigPageState();
}

class _GigPageState extends State<GigPage> {
  String selectedFilter = "";

  // 🔹 Mock gig data
  final List<Gig> gigs = [
    Gig(
      id: "1",
      title: "Bangkok Jazz Night",
      location: "Saxophone Pub",
      date: "Sep 20",
      imageUrl: "https://via.placeholder.com/400x250.png?text=Jazz+Night",
      genres: ["Jazz"],
    ),
    Gig(
      id: "2",
      title: "EDM Festival",
      location: "Glow Club",
      date: "Sep 25",
      imageUrl: "https://via.placeholder.com/400x250.png?text=EDM+Festival",
      genres: ["EDM", "Dance"],
    ),
    Gig(
      id: "3",
      title: "Rock Night",
      location: "Hard Rock Cafe",
      date: "Sep 18",
      imageUrl: "https://via.placeholder.com/400x250.png?text=Rock+Night",
      genres: ["Rock"],
    ),
    Gig(
      id: "4",
      title: "Acoustic Evening",
      location: "Brown Sugar Bar",
      date: "Sep 21",
      imageUrl: "https://via.placeholder.com/400x250.png?text=Acoustic+Evening",
      genres: ["Acoustic"],
    ),
    Gig(
      id: "5",
      title: "HipHop Battle",
      location: "Urban Stage",
      date: "Sep 23",
      imageUrl: "https://via.placeholder.com/400x250.png?text=HipHop+Battle",
      genres: ["HipHop"],
    ),
  ];

  // 🔹 Filter chips
  final List<String> filters = [
    "This Week",
    "This Month",
    "Nearby",
    "Jazz",
    "EDM",
    "Rock",
    "Acoustic",
    "HipHop",
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = selectedFilter.isEmpty
        ? gigs
        : gigs.where((g) {
            return g.genres.any(
              (genre) => genre.toLowerCase() == selectedFilter.toLowerCase(),
            ) ||
            (selectedFilter == "This Week" && g.date.contains("Sep 2")) || // mock filter
            (selectedFilter == "This Month");
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Gigs"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: Column(
        children: [
          // 🔹 Filters row
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
                    // ignore: deprecated_member_use
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

          // 🔹 Gigs Grid
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
                return GigCard(gig: filtered[i]); // ✅ reusable widget
              },
            ),
          ),
        ],
      ),
    );
  }
}
