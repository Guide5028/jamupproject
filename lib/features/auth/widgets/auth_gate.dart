import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/pages/login_page.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/nearby_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../main.dart' show MainNavigation;

/// AuthGate
/// --------
/// This widget decides which screen to show first: LoginPage or
/// MainNavigation. It also handles the "already logged in from a
/// previous session" case — that's the case where AuthService.signIn()
/// is NEVER called on this app launch, so we must re-run the post-login
/// side-effects ourselves.
///
/// Why this matters:
///   • User signs in today → AuthService.signIn() runs → OneSignal is
///     linked and location is saved. All good.
///   • User closes the app and opens it tomorrow → supabase already has
///     a cached session → signIn() is NOT called again → without the
///     code below, OneSignal never gets told who this device belongs to.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // If we booted with an existing session, rerun the "just logged in"
    // side-effects. Fire-and-forget: we don't want to block the UI.
    final existing = supabase.auth.currentUser;
    if (existing != null) {
      NotificationService.onUserLoggedIn(existing.id);
      // ignore: unawaited_futures
      NearbyService().saveMyLocation();
      // Pre-load favorites cache for hearts to render correctly on the
      // first frame the user sees after a "remember me" launch.
      // ignore: unawaited_futures
      FavoritesService.instance.loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
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
