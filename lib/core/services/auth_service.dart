import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/nearby_service.dart';
import '../services/favorites_service.dart';

/// AuthService
/// -----------
/// Thin wrapper around Supabase auth. The important teaching point here
/// is the ORDER of side-effects after a successful login:
///
///   1. ensureUserRow()  → make sure public.users has a row for this user
///      (you need that row because RLS policies and the RPC functions
///       read/write into it — without it, saveMyLocation() below would
///       fail with a foreign-key error).
///
///   2. NotificationService.onUserLoggedIn(userId)
///      → OneSignal now knows which user this device belongs to, and we
///        write the Player ID into device_tokens so your server can
///        push to the right person.
///
///   3. NearbyService().saveMyLocation()
///      → writes the user's lat/lng into public.users. Without this
///        step, the user is invisible to `get_nearby_musicians` RPC,
///        which is why the "nearby" feature looked broken.
class AuthService {
  final supabase = Supabase.instance.client;

  // ─── SIGN UP ─────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // "musician" | "venue"
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'jamup://auth-callback', // deep link
      data: {
        'name': name,
        'role': role,
      },
    );

    // ⛔️ Do NOT insert into public.users here.
    // Right after signUp() the user still has to click the confirmation
    // email — there is no session yet, so RLS would reject the insert.
    // We do the insert on the FIRST successful signIn instead.
    return res;
  }

  // ─── SIGN IN ─────────────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // 1) Make sure the public.users row exists before anything else
    //    tries to read it.
    await ensureUserRow();

    // 2) Hook this device into OneSignal under the user's id and sync
    //    the Player ID to device_tokens. SAFE to call even if OneSignal
    //    hasn't fully initialized yet — onUserLoggedIn handles that.
    final userId = res.user?.id;
    if (userId != null) {
      await NotificationService.onUserLoggedIn(userId);
    }

    // 3) Save the user's GPS position to public.users so OTHER users
    //    can discover them via the `get_nearby_musicians` RPC.
    //    Fire-and-forget is fine here — we do not want login to hang
    //    if GPS is slow.
    // ignore: unawaited_futures
    NearbyService().saveMyLocation();

    // 4) Pre-load the user's favorite gig IDs into the in-memory cache.
    //    Without this, every heart icon in the app would have to fire
    //    its own query on first paint. fire-and-forget is fine; cards
    //    show outline-heart until the cache resolves (typically <300ms).
    // ignore: unawaited_futures
    FavoritesService.instance.loadAll();

    return res;
  }

  // ─── ENSURE ROW IN public.users ──────────────────────────────
  Future<void> ensureUserRow() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existing = await supabase
        .from('users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      final meta = user.userMetadata ?? {};
      await supabase.from('users').insert({
        'id': user.id,
        'name': meta['name'] ?? user.email?.split('@').first ?? 'User',
        'email': user.email,
        'role': meta['role'] ?? 'musician',
        'avatar_url': meta['avatar_url'],
        'bio': meta['bio'],
        'genres': meta['genres'],
        'venue_type': meta['venueType'],
      });
    }
  }

  // ─── SIGN OUT ────────────────────────────────────────────────
  Future<void> signOut() async {
    // ORDER MATTERS:
    // onUserLoggedOut needs supabase.auth.currentUser still alive, because
    // it deletes a row from device_tokens that is keyed by user.id.
    // If we called signOut() first, currentUser would already be null.
    await NotificationService.onUserLoggedOut();
    // Clear the favorites cache so the next signed-in user doesn't briefly
    // see the previous user's hearts during the auth flicker.
    FavoritesService.instance.clear();
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
