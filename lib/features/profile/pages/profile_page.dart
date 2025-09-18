import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import 'setting_page.dart';
import 'edit_profile_page.dart';
import '../../auth/pages/login_page.dart'; // NEW

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut(); // NEW
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()), // NEW
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser; // NEW

    // If no user, show login prompt
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    // Extract user data
    final meta = user.userMetadata ?? {};
    final name = meta['name'] ?? "Unknown";
    final role = meta['role'] ?? "musician"; // musician or venue
    final bio = meta['bio'] ?? "";
    final image = meta['avatar_url'] ?? "https://via.placeholder.com/200.png?text=User";

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
                  backgroundImage: NetworkImage(image),
                ),
                const SizedBox(height: 12),
                Text(name, style: AppFonts.textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text(bio, style: AppFonts.textTheme.bodyMedium),
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
          if (role == "musician")
            _menuItem(Icons.music_note_outlined, "My Bookings", () {
              // TODO: navigate to musician bookings
            }),
          if (role == "venue")
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
            _logout(context); // NEW
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
