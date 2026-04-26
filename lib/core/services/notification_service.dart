import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// NotificationService
/// -------------------
/// Responsibilities are split into THREE phases so the code is predictable:
///
///   1) initialize()         → called ONCE in main(). Boots the OneSignal
///                             SDK and attaches listeners. Does NOT need a
///                             logged-in user.
///
///   2) onUserLoggedIn(id)   → called after the user signs in / signs up.
///                             Tells OneSignal "this device belongs to
///                             user <id>" and saves the Player ID into our
///                             Supabase `device_tokens` table.
///
///   3) onUserLoggedOut()    → called BEFORE supabase.auth.signOut().
///                             Removes the device_tokens row and clears
///                             OneSignal's external user id.
///
/// Why split it like this?
///   • OneSignal SDK must boot early so listeners are attached before the
///     first notification arrives.
///   • But the link "player_id ↔ user.id" can only exist AFTER login.
///   • Mixing both in one place was the original bug: initialize() ran
///     before the user existed, so registerDevice() silently returned.
class NotificationService {
  static final supabase = Supabase.instance.client;

  // ──────────────────────────────────────────────────────────────
  // PHASE 1 — SDK bootstrap (runs once in main.dart)
  // ──────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    // Verbose logs only help while developing. Turn OFF for production
    // builds to avoid leaking internal details in logcat.
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Boot the SDK with your OneSignal App ID.
    // Reference: https://documentation.onesignal.com/docs/flutter-sdk-setup
    OneSignal.initialize("08bf7c47-ef4a-49c7-9673-6ae912d7ea81");

    // Ask the OS for permission to display notifications.
    // On Android 13+ and all iOS versions this is REQUIRED, otherwise
    // the system silently drops every push.
    await OneSignal.Notifications.requestPermission(true);

    // ── Listener A: show banners even when app is in foreground ──
    // Without this, pushes received while the user is INSIDE the app
    // are hidden by the OS. event.notification.display() tells OneSignal
    // "yes, render the banner even though the app is open".
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // ── Listener B: react when user taps a notification ──
    // additionalData is a map you include when sending the push from
    // your server (e.g. {"gigId": "abc-123"}). Use it to deep-link
    // into the correct screen.
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      // TODO: route to the right page based on `data`.
      // Example: if (data?['gigId'] != null) Navigator.pushNamed(...);
      print("Notification clicked. Data = $data");
    });

    // ── Listener C: store the Player ID whenever it changes ──
    // This observer fires:
    //   • the first time OneSignal obtains a Player ID
    //   • whenever the user opts in/out of notifications
    //   • after a reinstall that produces a new token
    // Each time, IF a user is already logged in, sync the token to Supabase.
    OneSignal.User.pushSubscription.addObserver((state) async {
      final playerId = state.current.id;
      if (playerId == null) return;

      // Only save when we have an authenticated Supabase user.
      final user = supabase.auth.currentUser;
      if (user != null) {
        await _saveDeviceToken(user.id, playerId);
      }
    });
  }

  // ──────────────────────────────────────────────────────────────
  // PHASE 2 — user just logged in
  // ──────────────────────────────────────────────────────────────
  /// Call this from AuthService.signIn() and from your sign-up flow,
  /// right after Supabase confirms the user is authenticated.
  static Future<void> onUserLoggedIn(String userId) async {
    // Tell OneSignal "this device is now associated with userId".
    // This is OneSignal's recommended way to identify a user so the
    // same person can receive notifications across multiple devices.
    // Reference: https://documentation.onesignal.com/docs/aliases-external-id
    await OneSignal.login(userId);

    // Grab the current Player ID if it's already known. If the SDK is
    // still fetching one, the observer in initialize() will pick it up
    // as soon as it arrives, so either path works.
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      await _saveDeviceToken(userId, playerId);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // PHASE 3 — user is logging out
  // ──────────────────────────────────────────────────────────────
  /// Call this BEFORE supabase.auth.signOut(), because once signOut()
  /// runs we lose currentUser.id and cannot target the right row.
  static Future<void> onUserLoggedOut() async {
    final user = supabase.auth.currentUser;
    final playerId = OneSignal.User.pushSubscription.id;

    // Delete only the (user, device) pair we know about — that way other
    // devices the same user is still signed in on keep working.
    if (user != null && playerId != null) {
      try {
        await supabase
            .from('device_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('player_id', playerId);
      } catch (e) {
        // We swallow the error: logout must never fail because of this.
        print('Failed to clean device_tokens: $e');
      }
    }

    // Finally detach this device from the OneSignal external id.
    await OneSignal.logout();
  }

  // ──────────────────────────────────────────────────────────────
  // Private helper — the only place we write to device_tokens
  // ──────────────────────────────────────────────────────────────
  static Future<void> _saveDeviceToken(String userId, String playerId) async {
    try {
      // upsert() = INSERT if the row doesn't exist, UPDATE if it does.
      // Your table should have a UNIQUE constraint on (user_id, player_id)
      // so this behaves correctly. Without the constraint, upsert cannot
      // know which row to update and will insert duplicates.
      await supabase.from('device_tokens').upsert({
        'user_id': userId,
        'player_id': playerId,
      }, onConflict: 'user_id,player_id');
    } catch (e) {
      print('Failed to save device token: $e');
    }
  }
}
