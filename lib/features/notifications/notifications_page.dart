import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    Icon getNotificationIcon(String type) {
      switch (type) {
        case 'message':
          return const Icon(Icons.chat_bubble_outline);

        case 'gig_invite':
          return const Icon(Icons.music_note);

        case 'musician_follow':
          return const Icon(Icons.person_add);

        case 'nearby_gig':
          return const Icon(Icons.location_on);

        default:
          return const Icon(Icons.notifications_none);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder(
  stream: supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifications = snapshot.data!;

    if (notifications.isEmpty) {
      return const Center(
        child: Text("No notifications yet"),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];

        return Dismissible(
          key: Key(n['id'].toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (_) async {
            await supabase
                .from('notifications')
                .delete()
                .eq('id', n['id']);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),

          child: ListTile(
            onTap: () async {
              await supabase
                  .from('notifications')
                  .update({'is_read': true})
                  .eq('id', n['id']);
            },

            leading: getNotificationIcon(n['type']),

            title: Text(
              n['title'],
              style: TextStyle(
                fontWeight: n['is_read'] ? FontWeight.normal : FontWeight.bold,
              ),
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['message']),
                const SizedBox(height: 4),
                Text(
                  timeago.format(DateTime.parse(n['created_at'])),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
),
    );
  }
}
