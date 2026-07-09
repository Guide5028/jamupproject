import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:jamup_app/core/app_navigator.dart';

import 'package:jamup_app/features/booking/pages/booking_detail_page.dart';
import 'package:jamup_app/features/messages/pages/chat_page.dart';

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

  /// True only after OneSignal was actually initialized with a valid App ID.
  /// The login/logout phases check this so they stay completely dormant (no
  /// native calls, no log noise) while push isn't configured.
  static bool _enabled = false;

  // ──────────────────────────────────────────────────────────────
  // PHASE 1 — SDK bootstrap (runs once in main.dart)
  // ──────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    // Verbose logs only help while developing. Turn OFF for production
    // builds to avoid leaking internal details in logcat.
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Boot the SDK with your OneSignal App ID.
    // Reference: https://documentation.onesignal.com/docs/flutter-sdk-setup
    //
    // We DON'T use `!` here. If ONESIGNAL_APP_ID is missing, empty, or not a
    // real OneSignal App ID, we skip push setup so the app keeps launching AND
    // the SDK doesn't spam "Failed to get Android parameters" retries against a
    // bad id. OneSignal App IDs are UUIDs (8-4-4-4-12 hex), so we check that
    // shape. Drop a real UUID into .env and push turns back on automatically.
    final oneSignalId = dotenv.env['ONESIGNAL_APP_ID'];
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (oneSignalId == null || !uuidPattern.hasMatch(oneSignalId)) {
      debugPrint('⚠️ ONESIGNAL_APP_ID missing/invalid — skipping push setup. '
          'Expected a 36-char UUID like 1a2b3c4d-5e6f-7890-abcd-ef1234567890.');
      return;
    }
    _enabled = true;
    OneSignal.initialize(oneSignalId);

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
    // additionalData is the map you include when sending the push from
    // your Edge Function (e.g. {"type": "booking_request", "bookingId": "..."}).
    // We use the global navigatorKey so routing works even when the click
    // arrives before any widget's BuildContext exists.
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      debugPrint('Notification tapped. Data = $data');
      if (data == null) return;
      _handleNotificationTap(data);
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
  // Deep-link routing based on notification payload
  // ──────────────────────────────────────────────────────────────
  static void _handleNotificationTap(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final type = data['type'] as String? ?? '';
    final bookingId = data['bookingId'] as String?;
    final chatId = data['chatId'] as String?;

    if (type == 'message' && chatId != null) {
      // Open the chat directly
      nav.push(MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          name: '',
          avatar: '',
          otherUserId: '',
          isVenue: false, // will reload its own role
        ),
      ));
      return;
    }

    if ((type.startsWith('booking_') || type == 'booking_request') &&
        bookingId != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => BookingDetailPage(bookingId: bookingId),
      ));
      return;
    }

    // Fallback: if bookingId is present but type is unknown, open booking
    if (bookingId != null) {
      nav.push(MaterialPageRoute(
        builder: (_) => BookingDetailPage(bookingId: bookingId),
      ));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // PHASE 2 — user just logged in
  // ──────────────────────────────────────────────────────────────
  /// Call this from AuthService.signIn() and from your sign-up flow,
  /// right after Supabase confirms the user is authenticated.
  static Future<void> onUserLoggedIn(String userId) async {
    // Push not configured (no valid App ID) → do nothing, stay silent.
    if (!_enabled) return;

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
    // Push not configured → nothing was ever registered, so nothing to clean.
    if (!_enabled) return;

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
        debugPrint('Failed to clean device_tokens: $e');
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
      debugPrint('Failed to save device token: $e');
    }
  }
}
