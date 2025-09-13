import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import 'setting_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock user (later this will come from backend/auth provider)
    final user = {
      "name": "John Doe",
      "role": "Musician", // or "Venue Owner"
      "bio": "Jazz • Saxophone • Bangkok",
      "image": "https://via.placeholder.com/200.png?text=User",
      "genres": ["Jazz", "Blues"],
      "venueType": null, // if venue: "Club", "Bar", etc.
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🔹 User Info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user["image"] as String),
                ),
                const SizedBox(height: 12),
                Text(user["name"]! as String
                , style: AppFonts.textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text(user["bio"]! as String
                , style: AppFonts.textTheme.bodyMedium),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfilePage()),
                    );
                  },
                  child: const Text("Edit Profile",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),

          // 🔹 Role-Specific Section
          if (user["role"] == "Musician")
            _menuItem(Icons.music_note_outlined, "My Bookings", () {
              // TODO: navigate to musician bookings
            }),
          if (user["role"] == "Venue Owner")
            _menuItem(Icons.event_outlined, "My Gigs", () {
              // TODO: navigate to venue gigs
            }),

          _menuItem(Icons.favorite_border, "Favorites", () {
            // TODO: saved musicians/venues
          }),

          const Divider(),

          // 🔹 Settings & Support
          _menuItem(Icons.settings_outlined, "Settings", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }),
          _menuItem(Icons.help_outline, "Help Center", () {
            // TODO: navigate to help
          }),
          _menuItem(Icons.privacy_tip_outlined, "Privacy & Terms", () {
            // TODO: open terms page
          }),

          const Divider(),

          // 🔹 Auth
          _menuItem(Icons.logout, "Logout", () {
            // TODO: logout
          }),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkBrown),
      title: Text(title, style: AppFonts.textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right, color: AppColors.accentBrown),
      onTap: onTap,
    );
  }
}
