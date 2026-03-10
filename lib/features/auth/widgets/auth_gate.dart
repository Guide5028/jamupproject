import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/pages/login_page.dart';
import '../../../core/services/notification_service.dart';
import '../../../main.dart' show MainNavigation; // reuse your MainNavigation

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // If already have a session, go straight in
    if (supabase.auth.currentSession != null) {
      return const MainNavigation();
    }

    // Listen for auth state (incl. deep-link completion)
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supabase.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return const MainNavigation();
      },
    );
  }
}
