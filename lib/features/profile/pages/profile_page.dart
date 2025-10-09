import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import 'setting_page.dart';
import 'edit_profile_page.dart';
import '../../auth/pages/login_page.dart';
import '../../booking/pages/my_bookings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  Map<String, dynamic>? _userRow; // data from public.users
  Map<String, dynamic> get _meta => supabase.auth.currentUser?.userMetadata ?? {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final row = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _userRow = row ?? {};
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
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

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    // Prefer users table; fall back to metadata keys
    final name = (_userRow?['name'] ?? _meta['name'] ?? 'Unknown') as String;
    final bio = (_userRow?['bio'] ?? _meta['bio'] ?? '') as String;
    final role = ((_userRow?['role'] ?? _meta['role'] ?? 'musician') as String).toLowerCase();
    final avatarUrl = (_userRow?['avatar_url'] ?? _meta['avatar_url'] ??
        'https://via.placeholder.com/200.png?text=User') as String;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser, // pull to refresh
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl)),
                  const SizedBox(height: 12),
                  Text(name, style: AppFonts.textTheme.headlineLarge),
                  const SizedBox(height: 6),
                  if (bio.isNotEmpty)
                    Text(bio, style: AppFonts.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(role.toUpperCase(), style: AppFonts.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                      );
                      // reload after editing
                      await _loadUser();
                    },
                    child: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),

            if (role == 'musician')
              _menuItem(Icons.music_note_outlined, 'My Bookings', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                );
              }),
            if (role == 'venue')
              _menuItem(Icons.event_outlined, 'My Gigs', () {
                // TODO: navigate to venue gigs page
              }),

            _menuItem(Icons.favorite_border, 'Favorites', () {
              // TODO
            }),

            const Divider(),

            _menuItem(Icons.settings_outlined, 'Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            }),
            _menuItem(Icons.help_outline, 'Help Center', () {}),
            _menuItem(Icons.privacy_tip_outlined, 'Privacy & Terms', () {}),

            const Divider(),

            _menuItem(Icons.logout, 'Logout', _logout),
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
