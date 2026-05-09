import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/pay_label.dart';
import '../../../core/services/favorites_service.dart';

import '../../../models/gig.dart';

import '../../messages/data/messages_repository.dart';
import '../../messages/pages/chat_page.dart';

import '../../venues/pages/venue_detail_page.dart';
import '../../booking/data/booking_repository.dart';

class GigDetailPage extends StatelessWidget {
  final Gig gig;
  final BookingRepository bookingRepo = BookingRepository();

  GigDetailPage({super.key, required this.gig});

  Future<void> _bookGig(BuildContext context) async {
    final me = Supabase.instance.client.auth.currentUser;
    final startTime = gig.date;
    final endTime = gig.date.add(const Duration(hours: 2));

    // 🔒 Safety check (even if UI fails)
    if (me != null && me.id == gig.venueId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't book your own gig.")),
      );
      return;
    }

    try {
      final result = await bookingRepo.createBookingAndChat(
        gigId: gig.id,
        venueId: gig.venueId,
        startTime: startTime,
        endTime: endTime,
      );

      final booking = result['booking'] as Map<String, dynamic>;
      final chatId = result['chatId'] as String;

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            name: gig.location,
            avatar: gig.imageUrl,
            initialStatus: booking['status'] ?? 'pending',
            otherUserId: '',
            isVenue: false,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {}
    final role = (user?.userMetadata?['role'] ?? '').toString().toLowerCase();

    final isMusician = role == 'musician';
    final isVenue = role == 'venue';
    final isOwner = isVenue && user?.id == gig.venueId;

    final description = gig.description.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Reactive heart wired to FavoritesService.
          // ValueListenableBuilder rebuilds this single icon whenever the
          // favorites set changes — fast and isolated to this widget.
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesService.instance.ids,
            builder: (_, ids, __) {
              final isFav = ids.contains(gig.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : AppColors.darkBrown,
                ),
                tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => FavoritesService.instance.toggle(gig.id),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.darkBrown),
            onPressed: () => _showShareSheet(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 🖼️ Gig Image
          SizedBox(
            height: width * 0.65,
            width: double.infinity,
            child: Stack(
              children: [
                // Image
                Positioned.fill(
                  child: gig.imageUrl.isEmpty
                      ? _placeholderImage(width * 0.65)
                      : Image.network(
                          gig.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholderImage(width * 0.65),
                        ),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Title + info on image
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        gig.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              gig.location,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(gig.date),
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎵 Genres
                Wrap(
                  spacing: 8,
                  children: gig.genres.map(_buildTag).toList(),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoTile(
                      Icons.music_note,
                      "Role",
                      gig.roleNeeded.isNotEmpty ? gig.roleNeeded : "Musician",
                    ),
                    _infoTile(
                      Icons.people,
                      "Slots",
                      "${gig.slots}",
                    ),
                    _infoTile(
                      Icons.payments,
                      "Musician Pay",
                      payLabel(gig.payment, gig.paymentUnit),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          gig.applicants > 0
                              ? "${gig.applicants} musicians applied"
                              : "Be the first to apply",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 📍 LOCATION + DATE
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        gig.location,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.textTheme.bodyMedium?.copyWith(
                          color: AppColors.accentBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.accentBrown),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(gig.date),
                      style: AppFonts.textTheme.bodyMedium?.copyWith(
                        color: AppColors.accentBrown,
                      ),
                    ),
                  ],
                ),

                // 📍 DISTANCE
                if (gig.distance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me,
                            size: 14, color: AppColors.primaryGold),
                        const SizedBox(width: 4),
                        Text(
                          "${gig.distance!.toStringAsFixed(1)} km away",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ✅ About (REAL description)
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 6),
              Text("About this gig", style: AppFonts.textTheme.headlineMedium),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              description.isNotEmpty
                  ? description
                  : "No description provided yet.",
              style: AppFonts.textTheme.bodyLarge,
            ),
          ),

          const SizedBox(height: 24),

          // 🎯 Organizer
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VenueDetailPage(venueId: gig.venueId),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryGold,
                  child: Icon(Icons.business, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Organizer",
                      style: AppFonts.textTheme.bodyMedium,
                    ),
                    Text(
                      gig.location, // temporary venue name
                      style: AppFonts.textTheme.headlineMedium,
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ✅ ACTION SECTION (professional role-based UI)

          // 1) Musician => show Book Now button
          if (isMusician)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _bookGig(context),
                child: Text(
                  "Book Now",
                  style: AppFonts.textTheme.bodyLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // 2) Venue owner => show hosting badge (no booking button)
          if (isOwner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle,
                      color: AppColors.primaryGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "You are hosting this gig",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 Helpers

  void _showShareSheet(BuildContext context) {
    final mm = gig.date.month.toString().padLeft(2, '0');
    final dd = gig.date.day.toString().padLeft(2, '0');
    final dateStr = "${gig.date.year}-$mm-$dd";
    final payText = payLabel(gig.payment, gig.paymentUnit);
    final shareText = "🎵 ${gig.title}\n📍 ${gig.location}\n📅 $dateStr\n💰 $payText\n\nVia JamUp";

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text("Share Gig", style: AppFonts.textTheme.headlineMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryGold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.share, color: AppColors.primaryGold),
              ),
              title: const Text("Share to other apps"),
              subtitle: const Text("Send via WhatsApp, Line, etc."),
              onTap: () { Navigator.pop(context); Share.share(shareText, subject: gig.title); },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryGold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryGold),
              ),
              title: const Text("Send to a Chat"),
              subtitle: const Text("Share this gig in an existing conversation"),
              onTap: () { Navigator.pop(context); _showChatPickerSheet(context, shareText); },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatPickerSheet(BuildContext context, String shareText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ChatPickerSheet(shareText: shareText),
    );
  }

  Widget _placeholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child:
          const Icon(Icons.music_note, color: AppColors.accentBrown, size: 40),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppFonts.textTheme.bodyMedium,
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGold),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.accentBrown,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }

}

class _ChatPickerSheet extends StatefulWidget {
  final String shareText;
  const _ChatPickerSheet({required this.shareText});
  @override
  State<_ChatPickerSheet> createState() => _ChatPickerSheetState();
}

class _ChatPickerSheetState extends State<_ChatPickerSheet> {
  SupabaseClient get _supabase => Supabase.instance.client;
  late final Future<List<Map<String, dynamic>>> _convsFuture;

  @override
  void initState() {
    super.initState();
    _convsFuture = MessagesRepository().fetchConversations();
  }

  Future<void> _send(String chatId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': widget.shareText,
      'type': 'user',
      'created_at': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gig sent to chat")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text("Send to Chat", style: AppFonts.textTheme.headlineMedium),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _convsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator());
              }
              final convos = snap.data ?? [];
              if (convos.isEmpty) {
                return const Padding(padding: EdgeInsets.all(16), child: Text("No conversations yet."));
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: convos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = convos[i];
                    final avatar = (c['other_avatar'] ?? '') as String;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                        backgroundColor: AppColors.primaryGold.withOpacity(0.15),
                        child: avatar.isEmpty ? const Icon(Icons.person, color: AppColors.darkBrown) : null,
                      ),
                      title: Text(c['other_name'] ?? '', style: AppFonts.textTheme.bodyLarge),
                      subtitle: Text(c['status'] ?? '', style: AppFonts.textTheme.bodyMedium),
                      trailing: const Icon(Icons.send, size: 18, color: AppColors.primaryGold),
                      onTap: () => _send(c['chat_id'] as String),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
