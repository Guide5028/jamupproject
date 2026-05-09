// ============================================================================
// edit_profile_page.dart   —   Edit your own user row in `public.users`
// ============================================================================
// Teacher notes for Guide:
//  • The form is SHAPED by `role`. Musicians see genres + instruments +
//    hourly rate. Venues don't — those fields don't make sense for them.
//  • Uploading avatar is a 3-step dance:
//       1. Upload the file bytes to Storage bucket `avatars`
//       2. Get the public URL
//       3. Save that URL into users.avatar_url
//    Each step can fail independently, so each has its own try/catch path.
//  • FilterChip > free-text genre because it prevents typos like
//    "jazz ", "Jazz", "JAZZ" all counting as different genres.
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  SupabaseClient get _supabase => Supabase.instance.client;
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _instrumentsCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController();
  final _locationTextCtrl = TextEditingController();

  String role = 'musician';
  String avatarUrl = '';
  File? _newAvatar;

  // Same curated list as create_gig_page for consistency.
  static const _allGenres = <String>[
    'Jazz', 'Rock', 'Pop', 'EDM', 'Hip-Hop',
    'Classical', 'Acoustic', 'R&B', 'Folk', 'Blues',
  ];
  final Set<String> _selectedGenres = {};

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile().catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _instrumentsCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _locationTextCtrl.dispose();
    super.dispose();
  }

  // ── load ───────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    final row = await _supabase
        .from('users')
        .select(
            'name, bio, role, avatar_url, genres, instruments, hourly_rate, location_text')
        .eq('id', user.id)
        .maybeSingle();

    final genres = (row?['genres'] as List?)?.cast<String>() ?? <String>[];
    final instruments =
        (row?['instruments'] as List?)?.cast<String>() ?? <String>[];

    setState(() {
      _nameCtrl.text = (row?['name'] ?? '').toString();
      _bioCtrl.text = (row?['bio'] ?? '').toString();
      role = (row?['role'] ?? 'musician').toString();
      avatarUrl = (row?['avatar_url'] ?? '').toString();
      _instrumentsCtrl.text = instruments.join(', ');
      _hourlyRateCtrl.text = row?['hourly_rate'] != null
          ? (row!['hourly_rate'] as num).toStringAsFixed(0)
          : '';
      _locationTextCtrl.text = (row?['location_text'] ?? '').toString();
      _selectedGenres
        ..clear()
        ..addAll(genres);
      _loading = false;
    });
  }

  // ── avatar upload ──────────────────────────────────────────────────
  Future<String?> _uploadAvatar(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final ext = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      _snack('Only JPG or PNG please.');
      return null;
    }
    // Unique filename prevents CDN caching showing the OLD avatar after upload.
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '${user.id}/$fileName';

    await _supabase.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  // ── save ──────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      String finalAvatarUrl = avatarUrl;

      if (_newAvatar != null) {
        final uploaded = await _uploadAvatar(_newAvatar!);
        if (uploaded != null) finalAvatarUrl = uploaded;
      }

      // Parse instruments CSV → List<String>, trimmed, empty-filtered.
      final instruments = _instrumentsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // hourly_rate is nullable; let venues leave it blank.
      final hourly = double.tryParse(_hourlyRateCtrl.text.trim());

      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'role': role,
        'avatar_url': finalAvatarUrl,
        'genres': role == 'musician' ? _selectedGenres.toList() : <String>[],
        'instruments': role == 'musician' ? instruments : <String>[],
        'hourly_rate': role == 'musician' ? hourly : null,
        'location_text': _locationTextCtrl.text.trim(),
      };

      await _supabase.from('users').update(payload).eq('id', user.id);

      if (!mounted) return;
      _snack('Profile updated ✅');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to update: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── pickers ────────────────────────────────────────────────────────
  Future<void> _pick(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 75);
    if (x == null) return;
    setState(() => _newAvatar = File(x.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  // ── UI helpers ─────────────────────────────────────────────────────
  InputDecoration _dec(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text, style: AppFonts.textTheme.headlineMedium),
      );

  ImageProvider? _avatarProvider() {
    if (_newAvatar != null) return FileImage(_newAvatar!);
    final u = avatarUrl.trim();
    if (u.isEmpty) return null;
    return NetworkImage(u);
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final img = _avatarProvider();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // ── AVATAR ────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: img,
                        onBackgroundImageError:
                            img != null ? (_, __) {} : null,
                        child: img == null
                            ? const Icon(Icons.person,
                                size: 40, color: AppColors.accentBrown)
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
                            onPressed: _showImageSourceSheet,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _sectionHeader('About You'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _dec('Name / Venue',
                      prefix: const Icon(Icons.person_outline)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  maxLength: 300, // built-in counter, no custom widget needed
                  decoration: _dec('Bio',
                      hint: role == 'musician'
                          ? 'Tell venues about your style...'
                          : 'Tell musicians about your venue...'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationTextCtrl,
                  decoration: _dec('City / Area',
                      hint: 'e.g. Chiang Mai',
                      prefix: const Icon(Icons.location_city_outlined)),
                ),

                _sectionHeader('Role'),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: _dec('I am a...'),
                  items: const [
                    DropdownMenuItem(
                        value: 'musician', child: Text('Musician')),
                    DropdownMenuItem(
                        value: 'venue', child: Text('Venue Owner')),
                  ],
                  onChanged: (v) =>
                      setState(() => role = v ?? 'musician'),
                ),

                // ── MUSICIAN-ONLY FIELDS ──────────────────────────
                if (role == 'musician') ...[
                  _sectionHeader('Genres'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allGenres.map((g) {
                      final selected = _selectedGenres.contains(g);
                      return FilterChip(
                        label: Text(g),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedGenres.add(g);
                            } else {
                              _selectedGenres.remove(g);
                            }
                          });
                        },
                        selectedColor:
                            AppColors.primaryGold.withOpacity(0.25),
                        checkmarkColor: AppColors.darkBrown,
                      );
                    }).toList(),
                  ),

                  _sectionHeader('Instruments'),
                  TextFormField(
                    controller: _instrumentsCtrl,
                    decoration: _dec('Instruments you play',
                        hint: 'Saxophone, Piano',
                        prefix: const Icon(Icons.music_note_outlined)),
                  ),

                  _sectionHeader('Rate'),
                  TextFormField(
                    controller: _hourlyRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _dec('Hourly rate (฿)',
                        hint: 'e.g. 1500',
                        prefix: const Icon(Icons.payments_outlined)),
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
