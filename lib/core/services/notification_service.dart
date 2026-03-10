import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final supabase = Supabase.instance.client;

  static Future<void> initialize() async {

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize("08bf7c47-ef4a-49c7-9673-6ae912d7ea81");

    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);

    // Wait for push subscription
    OneSignal.User.pushSubscription.addObserver((state) {
      print("Push subscription state changed");
      final playerId = state.current.id;

      if (playerId != null) {
        print("Player ID: $playerId");
        registerDevice(playerId);
      }
    });

    print("OneSignal initialized");
  }

  static Future<void> registerDevice(String playerId) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    print("Device Token: $playerId");

    await supabase.from('device_tokens').upsert({
      'user_id': user.id,
      'player_id': playerId,
    });
  }
}