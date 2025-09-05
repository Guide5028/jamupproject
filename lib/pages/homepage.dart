import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // GlobalKey to control Scaffold for opening endDrawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the key
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5F0),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "J",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "JamUP",
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C1810),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF2C1810)),
            onPressed: () {
              // Open drawer using GlobalKey
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),

      // Modern JamUP Drawer
      endDrawer: Drawer(
        backgroundColor: const Color(0xFFF8F5F0),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drawer Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    'JamUP',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Main menu items
                ListTile(
                  leading: const Icon(Icons.people_outline,
                      color: Color(0xFF2C1810)),
                  title: Text('Explore Artists',
                      style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.contact_mail_outlined,
                      color: Color(0xFF2C1810)),
                  title: Text('Contact Us',
                      style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),

                const Divider(thickness: 1, height: 30),

                // Services Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Services',
                      style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B7355))),
                ),
                // Services Items
                ListTile(
                  leading:
                      const Icon(Icons.book_online, color: Color(0xFF2C1810)),
                  title: Text('Book Talent',
                      style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts,
                      color: Color(0xFF2C1810)),
                  title: Text('Manage Talent',
                      style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.search, color: Color(0xFF2C1810)),
                  title: Text('Discover Talent',
                      style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),

                const Divider(thickness: 1, height: 30),

                // Resources Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Resources',
                      style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B7355))),
                ),
                // Resources Items
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined,
                      color: Color(0xFF2C1810)),
                  title:
                      Text('Support', style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: Color(0xFF2C1810)),
                  title:
                      Text('Privacy', style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.rule_folder_outlined,
                      color: Color(0xFF2C1810)),
                  title: Text('Terms', style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading:
                      const Icon(Icons.help_outline, color: Color(0xFF2C1810)),
                  title: Text('Help Center',
                      style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),

                const SizedBox(height: 30),

                // Optional logout / version
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFF2C1810)),
                  title: Text('Logout', style: GoogleFonts.inter(fontSize: 16)),
                  onTap: () {},
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Version 1.0.0',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF8B7355))),
                ),
              ],
            ),
          ),
        ),
      ),

      // Body: Hero Banner + Feature Cards (your existing code)
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero Banner
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB8860B),
                  Color(0xFFDAA520),
                  Color(0xFFF4E4BC)
                ],
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
                    style: GoogleFonts.interTight(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        "https://images.unsplash.com/photo-1575193128585-bc7e2dbedbeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Feature Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
            children: const [
              FeatureCard(
                icon: Icons.people_outlined,
                gradient: [Color(0xFFB8860B), Color(0xFFDAA520)],
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
                gradient: [Color(0xFFDAA520), Color(0xFFF4E4BC)],
                title: "Upcoming Events",
                subtitle: "Never miss a show",
              ),
              FeatureCard(
                icon: Icons.chat_bubble_outline,
                gradient: [Color(0xFFB8860B), Color(0xFFCD853F)],
                title: "Messages",
                subtitle: "Stay in touch",
              ),
            ],
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFDAA520),
        unselectedItemColor: const Color(0xFF8B7355),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined), label: "Search"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined), label: "Notifications"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

// Reusable Feature Card Widget
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
            color: Color(0x1A000000),
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
                color: const Color(0xFF8B7355),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.interTight(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C1810),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
