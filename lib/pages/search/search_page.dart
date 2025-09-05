import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/fonts.dart';
import '../../utils/constants.dart';
import '../../models/musician.dart';
import '../../models/venue.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data
  final List<Musician> musicians = [
    Musician(
        id: '1',
        name: 'Alice',
        genres: ['EDM', 'Dance'],
        type: 'Solo',
        profileImage: AppConstants.localPlaceholder),
    Musician(
        id: '2',
        name: 'Bob & Band',
        genres: ['Jazz', 'Pop'],
        type: 'Band',
        profileImage: AppConstants.localPlaceholder),
  ];

  final List<Venue> venues = [
    Venue(
        id: '1',
        name: 'Club Paradise',
        type: 'Club',
        location: 'Downtown',
        imageUrl: AppConstants.localPlaceholder),
    Venue(
        id: '2',
        name: 'Sunset Restaurant',
        type: 'Restaurant',
        location: 'Beachside',
        imageUrl: AppConstants.localPlaceholder),
    Venue(
        id: '3',
        name: 'Moonlight Bar',
        type: 'Bar',
        location: 'City Center',
        imageUrl: AppConstants.localPlaceholder),
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

  Widget _buildMusicianCard(Musician musician) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: SizedBox(
          width: 50,
          height: 50,
          child: CircleAvatar(
            backgroundImage: AssetImage(musician.profileImage),
          ),
        ),
        title: Text(musician.name, style: AppFonts.textTheme.headlineMedium),
        subtitle: Text(
          "${musician.genres.join(', ')} • ${musician.type}",
          style: AppFonts.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildVenueCard(Venue venue) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: SizedBox(
          width: 50,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              venue.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(venue.name, style: AppFonts.textTheme.headlineMedium),
        subtitle: Text(
          "${venue.type} • ${venue.location}",
          style: AppFonts.textTheme.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: AppColors.background,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGold,
            unselectedLabelColor: AppColors.accentBrown,
            indicatorColor: AppColors.primaryGold,
            tabs: const [
              Tab(text: 'Musicians'),
              Tab(text: 'Venues'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Musicians tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: musicians.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMusicianCard(musicians[index]),
                  );
                },
              ),
              // Venues tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: venues.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildVenueCard(venues[index]),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
