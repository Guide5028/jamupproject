import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _genreCtrl = TextEditingController(); // keep simple for now

  String role = "musician";
  String avatarUrl = "";
  File? _newAvatar;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    final row = await supabase
        .from('users')
        .select('name, bio, role, avatar_url, genres')
        .eq('id', user.id)
        .maybeSingle();

    final genres = (row?['genres'] as List?)?.cast<String>() ?? <String>[];

    setState(() {
      _nameCtrl.text = (row?['name'] ?? '').toString();
      _bioCtrl.text = (row?['bio'] ?? '').toString();
      role = (row?['role'] ?? 'musician').toString();
      avatarUrl = (row?['avatar_url'] ?? '').toString();
      _genreCtrl.text = genres.isNotEmpty ? genres.first : '';
      loading = false;
    });
  }

  Future<String?> _uploadAvatar(File file) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // ✅ cache-busting filename
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = "avatar_${DateTime.now().millisecondsSinceEpoch}.$ext";
    final path = "${user.id}/$fileName";

    await supabase.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      String finalAvatarUrl = avatarUrl;

      if (_newAvatar != null) {
        final uploaded = await _uploadAvatar(_newAvatar!);
        if (uploaded != null) finalAvatarUrl = uploaded;
      }

      final name = _nameCtrl.text.trim();
      final bio = _bioCtrl.text.trim();
      final genre = _genreCtrl.text.trim();

      // users.genres is text[]
      final genres =
          (role == "musician" && genre.isNotEmpty) ? [genre] : <String>[];

      await supabase.from('users').update({
        'name': name,
        'bio': bio,
        'role': role,
        'avatar_url': finalAvatarUrl,
        'genres': genres,
      }).eq('id', user.id);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _pick(ImageSource src) async {
    final picked = await _picker.pickImage(source: src, imageQuality: 75);
    if (picked == null) return;
    setState(() => _newAvatar = File(picked.path));
  }

  void _showImageSourceAction() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  ImageProvider? _avatarProvider() {
    if (_newAvatar != null) return FileImage(_newAvatar!);
    final u = avatarUrl.trim();
    if (u.isEmpty) return null;
    return NetworkImage(u);
  }

  @override
  Widget build(BuildContext context) {
    final img = _avatarProvider();

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: img,
                      onBackgroundImageError:
                          img != null ? (_, __) {} : null, // ✅ key fix
                      child: img == null
                          ? const Icon(Icons.person,
                              size: 36, color: AppColors.accentBrown)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                          onPressed: _showImageSourceAction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Name / Venue",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Name is required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: "musician", child: Text("Musician")),
                  DropdownMenuItem(value: "venue", child: Text("Venue Owner")),
                ],
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => role = val ?? "musician"),
              ),
              const SizedBox(height: 16),
              if (role == "musician")
                TextFormField(
                  controller: _genreCtrl,
                  decoration: const InputDecoration(
                    labelText: "Primary Genre (e.g. Jazz)",
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saving ? null : _saveProfile,
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Save Changes",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
