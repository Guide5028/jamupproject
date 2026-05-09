import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // ── Change Password ─────────────────────────────────────────────
  Future<void> _showChangePasswordDialog() async {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              title: Text('Change Password',
                  style: AppFonts.textTheme.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold),
                  onPressed: () async {
                    final newPass = newPassCtrl.text.trim();
                    final confirmPass = confirmCtrl.text.trim();

                    if (newPass.length < 6) {
                      setDialogState(() =>
                          errorText = 'Password must be at least 6 characters');
                      return;
                    }
                    if (newPass != confirmPass) {
                      setDialogState(() => errorText = 'Passwords do not match');
                      return;
                    }

                    try {
                      await Supabase.instance.client.auth.updateUser(
                        UserAttributes(password: newPass),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Password updated successfully ✅')),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => errorText = e.toString());
                    }
                  },
                  child: const Text('Update',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    newPassCtrl.dispose();
    confirmCtrl.dispose();
  }

  // ── Privacy & Terms ─────────────────────────────────────────────
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Privacy & Terms', style: AppFonts.textTheme.headlineMedium),
        content: SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'JamUp collects only the information you choose to share when '
            'creating your profile — such as name, location, and profile '
            'photo. This data is used solely to match musicians with venues '
            'and to personalise your experience.\n\n'
            'We do not sell your personal data to third parties.\n\n'
            'Terms of Service\n\n'
            'By using JamUp you agree to use the platform respectfully and '
            'only for legitimate booking and networking purposes. '
            'Misuse, harassment, or spam may result in account suspension.\n\n'
            'For questions, contact support@jamup.app.',
            style: AppFonts.textTheme.bodyMedium,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold),
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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

          // 🔹 Dark mode toggle (visual-only for now — full ThemeProvider deferred)
          SwitchListTile(
            title: Text("Dark Mode", style: AppFonts.textTheme.bodyLarge),
            value: darkMode,
            activeColor: AppColors.primaryGold,
            onChanged: (val) {
              setState(() => darkMode = val);
            },
          ),
          const Divider(),

          // 🔹 Change password
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.darkBrown),
            title:
                Text("Change Password", style: AppFonts.textTheme.bodyLarge),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.accentBrown),
            onTap: _showChangePasswordDialog,
          ),
          const Divider(),

          // 🔹 Privacy & Terms
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.darkBrown),
            title:
                Text("Privacy & Terms", style: AppFonts.textTheme.bodyLarge),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.accentBrown),
            onTap: _showPrivacyDialog,
          ),
        ],
      ),
    );
  }
}
