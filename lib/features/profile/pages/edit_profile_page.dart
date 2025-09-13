import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Mock initial values (later load from backend/auth)
  String name = "John Doe";
  String bio = "Jazz • Saxophone • Bangkok";
  String role = "Musician"; // or "Venue Owner"
  String genre = "Jazz";
  String venueType = "";

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
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                          "https://via.placeholder.com/200.png?text=User"),
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
                          onPressed: () {
                            // TODO: open image picker
                          },
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
                  DropdownMenuItem(value: "Musician", child: Text("Musician")),
                  DropdownMenuItem(value: "Venue Owner", child: Text("Venue Owner")),
                ],
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => role = val ?? "Musician"),
              ),
              const SizedBox(height: 16),

              // 🔹 Genre (for Musicians only)
              if (role == "Musician")
                TextFormField(
                  initialValue: genre,
                  decoration: const InputDecoration(
                    labelText: "Primary Genre",
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (val) => genre = val ?? "",
                ),

              // 🔹 Venue Type (for Venue Owners only)
              if (role == "Venue Owner")
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
                      // TODO: send updated profile to backend
                      Navigator.pop(context);
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
