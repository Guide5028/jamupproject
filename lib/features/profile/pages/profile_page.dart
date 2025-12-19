import 'package:flutter/material.dart';
import 'package:jamup_app/features/booking/pages/venue_bookings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../auth/pages/login_page.dart';
import '../../booking/pages/my_bookings_page.dart';
import '../data/profile_repository.dart';
import '../widgets/profile_avatar.dart';
import 'edit_profile_page.dart';
import 'setting_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  final repo = ProfileRepository();

  bool loading = true;
  Map<String, dynamic> userRow = {};

  Map<String, dynamic> get meta =>
      supabase.auth.currentUser?.userMetadata ?? {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    setState(() => loading = true);
    try {
      final row = await repo.getMyProfile();
      setState(() {
        userRow = row;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = supabase.auth.currentUser;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    final name = (userRow['name'] ?? meta['name'] ?? 'Unknown').toString();
    final bio = (userRow['bio'] ?? meta['bio'] ?? '').toString();
    final role = (userRow['role'] ?? meta['role'] ?? 'musician')
        .toString()
        .toLowerCase();
    final avatarUrl =
        (userRow['avatar_url'] ?? meta['avatar_url'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  ProfileAvatar(url: avatarUrl, radius: 50),
                  const SizedBox(height: 12),
                  Text(name, style: AppFonts.textTheme.headlineLarge),
                  const SizedBox(height: 6),
                  if (bio.isNotEmpty)
                    Text(bio, style: AppFonts.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(role.toUpperCase(),
                      style: AppFonts.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfilePage()),
                      );
                      await load();
                    },
                    child: const Text('Edit Profile',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            if (role == 'musician')
              _menuItem(Icons.music_note_outlined, 'My Bookings', () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyBookingsPage()));
              }),
            if (role == 'venue')
              _menuItem(Icons.assignment_outlined, 'Booking Requests', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VenueBookingsPage()),
                );
              }),
            _menuItem(Icons.favorite_border, 'Favorites', () {}),
            const Divider(),
            _menuItem(Icons.settings_outlined, 'Settings', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()));
            }),
            _menuItem(Icons.help_outline, 'Help Center', () {}),
            _menuItem(Icons.privacy_tip_outlined, 'Privacy & Terms', () {}),
            const Divider(),
            _menuItem(Icons.logout, 'Logout', logout),
          ],
        ),
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
