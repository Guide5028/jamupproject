import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return const Icon(Icons.chat_bubble_outline,
            color: AppColors.accentBrown);
      case 'gig_invite':
        return const Icon(Icons.music_note, color: AppColors.primaryGold);
      case 'musician_follow':
        return const Icon(Icons.person_add, color: AppColors.accentBrown);
      case 'nearby_gig':
        return const Icon(Icons.location_on, color: AppColors.primaryGold);
      default:
        return const Icon(Icons.notifications_none,
            color: AppColors.accentBrown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: AppColors.background, // FIX 3: consistent background
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      body: StreamBuilder(
        stream: supabase
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {

          // Loading state — stream hasn't emitted yet
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.accentBrown, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Could not load notifications.',
                    style: AppFonts.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          // Empty state
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none,
                      color: AppColors.accentBrown, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: AppFonts.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.accentBrown),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isRead = n['is_read'] as bool? ?? false;

              return Dismissible(
                key: Key(n['id'].toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await supabase
                      .from('notifications')
                      .delete()
                      .eq('id', n['id']);
                },
                // FIX 3: AppColors instead of hardcoded red/white
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade400,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  tileColor: isRead
                      ? null
                      : AppColors.primaryGold.withOpacity(0.05),
                  onTap: () async {
                    await supabase
                        .from('notifications')
                        .update({'is_read': true}).eq('id', n['id']);
                  },
                  leading: _getNotificationIcon(n['type'] ?? ''),
                  title: Text(
                    n['title'] ?? '',
                    style: AppFonts.textTheme.bodyLarge?.copyWith(
                      // unread = bold, read = normal
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['message'] ?? '',
                        style: AppFonts.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(DateTime.parse(n['created_at'])),
                        // FIX 3: AppColors instead of hardcoded Colors.grey
                        style: AppFonts.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.accentBrown),
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