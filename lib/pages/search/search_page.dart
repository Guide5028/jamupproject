import 'package:flutter/material.dart';
import 'package:jamup_project/models/musician.dart';
import 'package:jamup_project/models/venue.dart';
import 'package:jamup_project/widgets/app_image.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data (replace with API or DB later)
  final List<Musician> musicians = [
    Musician(
      name: "Alice Smith",
      genre: "Jazz",
      type: "Solo",
      imageUrl: "assets/images/musician1.jpg",
    ),
    Musician(
      name: "The Beats",
      genre: "Rock",
      type: "Band",
      imageUrl: "assets/images/musician2.jpg",
    ),
    Musician(
      name: "DJ Pulse",
      genre: "EDM",
      type: "Solo",
      imageUrl: "assets/images/musician3.jpg",
    ),
  ];

  final List<Venue> venues = [
    Venue(
      name: "Groove Bar",
      type: "Bar",
      imageUrl: "assets/images/venue1.jpg",
    ),
    Venue(
      name: "Moonlight Club",
      type: "Club",
      imageUrl: "assets/images/venue2.jpg",
    ),
    Venue(
      name: "Jazz Garden",
      type: "Restaurant",
      imageUrl: "assets/images/venue3.jpg",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Musicians"),
            Tab(text: "Venues"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMusicianGrid(),
          _buildVenueGrid(),
        ],
      ),
    );
  }

  // 🔹 Grid for musicians
  Widget _buildMusicianGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: musicians.length,
      itemBuilder: (context, index) {
        final musician = musicians[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppImage(
                  imageUrl: musician.imageUrl,
                  borderRadius: 12,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      musician.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${musician.genre} • ${musician.type}",
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Grid for venues
  Widget _buildVenueGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: venues.length,
      itemBuilder: (context, index) {
        final venue = venues[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppImage(
                  imageUrl: venue.imageUrl,
                  borderRadius: 12,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      venue.type,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
