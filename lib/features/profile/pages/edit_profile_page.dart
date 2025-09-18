import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // NEW
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
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker(); // NEW

  // Profile fields
  String name = "";
  String bio = "";
  String role = "musician";
  String genre = "";
  String venueType = "";
  String avatarUrl = "https://via.placeholder.com/200.png?text=User";

  File? _newAvatar; // NEW

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final meta = user.userMetadata ?? {};
    setState(() {
      name = meta['name'] ?? "";
      bio = meta['bio'] ?? "";
      role = meta['role'] ?? "musician";
      genre = meta['genre'] ?? "";
      venueType = meta['venueType'] ?? "";
      avatarUrl = meta['avatar_url'] ?? avatarUrl;
    });
  }

  Future<String?> _uploadAvatar(File file) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final fileExt = file.path.split('.').last;
      final fileName = "avatar.$fileExt"; // always overwrite same file
      final filePath = "${user.id}/$fileName"; // 👈 per-user folder

      await supabase.storage.from('avatars').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true), // overwrite old
          );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint("Avatar upload error: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      String? uploadedUrl = avatarUrl;
      if (_newAvatar != null) {
        uploadedUrl = await _uploadAvatar(_newAvatar!); // NEW
      }

      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'bio': bio,
            'role': role,
            'genre': genre,
            'venueType': venueType,
            'avatar_url': uploadedUrl,
          },
        ),
      );

      await supabase.from('users').update({
        'name': name,
        'bio': bio,
        'role': role,
        'avatar_url': uploadedUrl,
      }).eq('id', user.id);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated ✅")),
      );
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    }
  }

  // NEW: pick from gallery
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newAvatar = File(picked.path);
      });
    }
  }

  // NEW: pick from camera
  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _newAvatar = File(picked.path);
      });
    }
  }

  // NEW: show bottom sheet with options
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
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🔹 Profile picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _newAvatar != null
                          ? FileImage(_newAvatar!)
                          : NetworkImage(avatarUrl) as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGold,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                          onPressed: _showImageSourceAction, // NEW
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Name
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: "Name / Venue",
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => name = val ?? "",
              ),
              const SizedBox(height: 16),

              // 🔹 Bio
              TextFormField(
                initialValue: bio,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                ),
                onSaved: (val) => bio = val ?? "",
              ),
              const SizedBox(height: 16),

              // 🔹 Role
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
                  initialValue: genre,
                  decoration: const InputDecoration(
                    labelText: "Primary Genre",
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => genre = val ?? "",
                ),

              if (role == "venue")
                TextFormField(
                  initialValue: venueType,
                  decoration: const InputDecoration(
                    labelText: "Venue Type (e.g. Club, Bar, Restaurant)",
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => venueType = val ?? "",
                ),

              const SizedBox(height: 24),

              // 🔹 Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _saveProfile();
                    }
                  },
                  child: const Text("Save Changes",
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
