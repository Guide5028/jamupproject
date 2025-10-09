import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';                // for MainNavigation
import '../pages/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // Immediate check (cold start)
    if (supabase.auth.currentSession != null) {
      return const MainNavigation();
    }

    // React to session changes (login/logout, token refresh, email confirm)
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session == null) {
          return const LoginPage();
        }
        return const MainNavigation();
      },
    );
  }
}
