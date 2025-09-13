import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: ListView(
        children: [
          // 🔹 Notifications toggle
          SwitchListTile(
            title: Text("Enable Notifications",
                style: AppFonts.textTheme.bodyLarge),
            value: notificationsEnabled,
            activeColor: AppColors.primaryGold,
            onChanged: (val) {
              setState(() => notificationsEnabled = val);
            },
          ),
          const Divider(),

          // 🔹 Dark mode toggle
          SwitchListTile(
            title: Text("Dark Mode", style: AppFonts.textTheme.bodyLarge),
            value: darkMode,
            activeColor: AppColors.primaryGold,
            onChanged: (val) {
              setState(() => darkMode = val);
              // TODO: integrate real theme switching
            },
          ),
          const Divider(),

          // 🔹 Change password
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.darkBrown),
            title: Text("Change Password", style: AppFonts.textTheme.bodyLarge),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.accentBrown),
            onTap: () {
              // TODO: navigate to change password page
            },
          ),
          const Divider(),

          // 🔹 Privacy & Terms
          ListTile(
            leading:
                const Icon(Icons.privacy_tip_outlined, color: AppColors.darkBrown),
            title:
                Text("Privacy & Terms", style: AppFonts.textTheme.bodyLarge),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.accentBrown),
            onTap: () {
              // TODO: open privacy/terms page
            },
          ),
        ],
      ),
    );
  }
}
