import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/musician.dart';
import '../../../models/gig.dart';
import '../widgets/musician_card.dart';
import '../widgets/gig_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String query = "";

  // 🔹 Mock Musicians
  final List<Musician> musicians = [
    Musician(
      id: "1",
      name: "DJ Nova",
      genre: "EDM",
      type: "Solo",
      imageUrl: "https://via.placeholder.com/300x200.png?text=DJ+Nova",
    ),
    Musician(
      id: "2",
      name: "Luna Jazz Duo",
      genre: "Jazz",
      type: "Duo",
      imageUrl: "https://via.placeholder.com/300x200.png?text=Jazz+Duo",
    ),
    Musician(
      id: "3",
      name: "The HipHop Crew",
      genre: "HipHop",
      type: "Band",
      imageUrl: "https://via.placeholder.com/300x200.png?text=HipHop+Crew",
    ),
  ];

  // 🔹 Mock Gigs
  final List<Gig> gigs = [
    Gig(
      id: "1",
      title: "Bangkok Jazz Night",
      location: "Saxophone Pub",
      date: "2025-09-10",
      imageUrl: "https://via.placeholder.com/300x200.png?text=Jazz+Night",
      genres: ["Jazz"],
    ),
    Gig(
      id: "2",
      title: "EDM Festival",
      location: "Glow Club",
      date: "2025-09-15",
      imageUrl: "https://via.placeholder.com/300x200.png?text=EDM+Festival",
      genres: ["EDM", "Dance"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Search"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.accentBrown,
          indicatorColor: AppColors.primaryGold,
          tabs: const [
            Tab(text: "Musicians"),
            Tab(text: "Gigs"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => query = val),
              decoration: InputDecoration(
                hintText: "Search musicians or gigs...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 🔹 Filters
          if (_tabController.index == 0)
            _buildMusicianFilters()
          else
            _buildGigFilters(),

          const SizedBox(height: 10),

          // 🔹 Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMusicianGrid(),
                _buildGigGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Musician Filters
  Widget _buildMusicianFilters() {
    final filters = ["EDM", "Jazz", "Pop", "HipHop", "Dance"];
    return _chipRow(filters);
  }

  // ✅ Gig Filters
  Widget _buildGigFilters() {
    final filters = ["This Week", "This Month", "Nearby"];
    return _chipRow(filters);
  }

  Widget _chipRow(List<String> filters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: filters.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(f),
              selected: query == f,
              onSelected: (_) => setState(() => query = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ✅ Musicians Grid
  Widget _buildMusicianGrid() {
    final filtered = musicians.where((m) {
      return query.isEmpty ||
          m.name.toLowerCase().contains(query.toLowerCase()) ||
          m.genre.toLowerCase() == query.toLowerCase();
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) => MusicianCard(musician: filtered[i]),
    );
  }

  // ✅ Gigs Grid
  Widget _buildGigGrid() {
    final filtered = gigs.where((g) {
      return query.isEmpty ||
          g.title.toLowerCase().contains(query.toLowerCase()) ||
          g.genres.any((genre) => genre.toLowerCase() == query.toLowerCase());
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) => GigCard(gig: filtered[i]),
    );
  }
}
