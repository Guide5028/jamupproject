import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../utils/fonts.dart';
import '../../utils/constants.dart';
import '../search/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const SearchPage(),
    const Center(child: Text('Notifications Page')),
    const Center(child: Text('Profile Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondaryGold, AppColors.primaryGold],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "J",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: AppFonts.appBarTitle,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.darkBrown),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: const CustomDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.accentBrown,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

// ---------------- Custom Drawer ----------------
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondaryGold, AppColors.primaryGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text(
                        "J",
                        style: GoogleFonts.roboto(
                            fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppConstants.appName,
                      style: GoogleFonts.roboto(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _drawerItem(Icons.people_outline, 'Explore Artists'),
              _drawerItem(Icons.contact_mail_outlined, 'Contact Us'),
              const Divider(thickness: 1, height: 30),
              _drawerSection('Services'),
              _drawerItem(Icons.book_online, 'Book Talent'),
              _drawerItem(Icons.manage_accounts, 'Manage Talent'),
              _drawerItem(Icons.search, 'Discover Talent'),
              const Divider(thickness: 1, height: 30),
              _drawerSection('Resources'),
              _drawerItem(Icons.support_agent_outlined, 'Support'),
              _drawerItem(Icons.privacy_tip_outlined, 'Privacy'),
              _drawerItem(Icons.rule_folder_outlined, 'Terms'),
              _drawerItem(Icons.help_outline, 'Help Center'),
              const SizedBox(height: 30),
              _drawerItem(Icons.logout, 'Logout'),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(AppConstants.version,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.accentBrown)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkBrown),
      title: Text(title, style: GoogleFonts.inter(fontSize: 16)),
      onTap: () {},
    );
  }

  Padding _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title,
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentBrown)),
    );
  }
}

// ---------------- Home Content ----------------
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero Banner
        Container(
          height: width * 0.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondaryGold, AppColors.primaryGold, Color(0xFFF4E4BC)],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Connect. Create. Collaborate.",
                  style: AppFonts.textTheme.headlineLarge,
                ),
              ),
              Container(
                height: width * 0.25,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(AppConstants.placeholderImage),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Feature Cards Grid
        GridView.count(
          crossAxisCount: width > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.8,
          children: const [
            FeatureCard(
              icon: Icons.people_outlined,
              gradient: [AppColors.secondaryGold, AppColors.primaryGold],
              title: "Find Musicians",
              subtitle: "Connect with talented artists",
            ),
            FeatureCard(
              icon: Icons.location_on_outlined,
              gradient: [Color(0xFFCD853F), Color(0xFFD2691E)],
              title: "Find Venues",
              subtitle: "Discover perfect spaces",
            ),
            FeatureCard(
              icon: Icons.event_outlined,
              gradient: [AppColors.primaryGold, Color(0xFFF4E4BC)],
              title: "Upcoming Events",
              subtitle: "Never miss a show",
            ),
            FeatureCard(
              icon: Icons.chat_bubble_outline,
              gradient: [AppColors.secondaryGold, Color(0xFFCD853F)],
              title: "Messages",
              subtitle: "Stay in touch",
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Feature Card ----------------
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: AppColors.shadowColor,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.accentBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
