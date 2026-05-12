
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../messages/pages/chat_page.dart';
import '../controllers/booking_controller.dart';
import '../data/booking_repository.dart';

enum _StatusFilter {
  all('All', null),
  pending('Pending', 'pending'),
  confirmed('Confirmed', 'confirmed'),
  declined('Declined', 'declined');

  const _StatusFilter(this.label, this.value);
  final String label;
  final String? value; // null means "no filter"
}

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  _StatusFilter _selected = _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    String musicianId = '';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      musicianId = user?.id ?? '';
    } catch (_) {}

    return ChangeNotifierProvider(
      create: (_) => BookingController(BookingRepository())
        ..loadBookingsForMusician(musicianId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("My Bookings"),
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.darkBrown),
        ),
        body: Consumer<BookingController>(
          builder: (context, ctrl, _) {
            if (ctrl.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (ctrl.error != null) {
              return _errorState(ctrl.error!);
            }

            final all = ctrl.bookings;
            final visible = _selected.value == null
                ? all
                : all
                    .where((b) =>
                        (b['status'] ?? '').toString() == _selected.value)
                    .toList();

            return Column(
              children: [
                _filterChips(),
                Expanded(
                  child: visible.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, i) =>
                              _bookingTile(visible[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Filter chips row ─────────────────────────────────────────────
  Widget _filterChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _StatusFilter.values.map((f) {
          final isSelected = _selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selected = f),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryGold.withOpacity(0.25),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.darkBrown : AppColors.accentBrown,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.accentBrown.withOpacity(0.3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Single booking row ───────────────────────────────────────────
  Widget _bookingTile(Map<String, dynamic> booking) {
    final gig = (booking['gigs'] ?? {}) as Map<String, dynamic>;
    final status = (booking['status'] ?? 'pending').toString();
    final venue = (gig['location'] ?? 'Unknown venue').toString();
    final title = (gig['title'] ?? 'Untitled gig').toString();
    final dateStr = (gig['date'] ?? '').toString();
    final formattedDate = _prettyDate(dateStr);
    final avatar = (gig['image_url'] ?? '').toString();

    final (icon, color) = _statusVisuals(status);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.accentBrown.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: AppFonts.textTheme.bodyLarge),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.accentBrown),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(venue,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.textTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.accentBrown),
                  const SizedBox(width: 4),
                  Text(formattedDate, style: AppFonts.textTheme.bodyMedium),
                  const SizedBox(width: 10),
                  _statusPill(status, color),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chat_bubble_outline,
            color: AppColors.accentBrown),
        onTap: () async {
          final navigator = Navigator.of(context);
          final repo = BookingRepository();
          final bookingId = booking['id'].toString();
          final chatId = await repo.getChatIdForBooking(bookingId);
          if (!mounted) return;
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ChatPage(
                chatId: chatId,
                bookingId: bookingId,
                name: venue,
                avatar: avatar,
                initialStatus: status,
                otherUserId: '',
                isVenue: false,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  (IconData, Color) _statusVisuals(String status) {
    switch (status) {
      case 'confirmed':
        return (Icons.check_circle, const Color(0xFF1D9E75));
      case 'declined':
      case 'cancelled':
        return (Icons.cancel, const Color(0xFFE24B4A));
      default:
        return (Icons.hourglass_bottom, const Color(0xFFEF9F27));
    }
  }

  String _prettyDate(String iso) {
    if (iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} '
        '${months[dt.month - 1]} ${dt.year}';
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        const Center(
          child: Icon(Icons.event_busy,
              size: 64, color: AppColors.accentBrown),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _selected == _StatusFilter.all
                ? 'No bookings yet'
                : 'No ${_selected.label.toLowerCase()} bookings',
            style: AppFonts.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _selected == _StatusFilter.all
                ? 'Browse gigs and tap "Book Now" — your requests will land here.'
                : 'Try a different filter to see other bookings.',
            textAlign: TextAlign.center,
            style: AppFonts.textTheme.bodyMedium
                ?.copyWith(color: AppColors.accentBrown),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 36, color: AppColors.accentBrown),
            const SizedBox(height: 8),
            Text('Could not load bookings',
                style: AppFonts.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(message,
                style: AppFonts.textTheme.bodyMedium?.copyWith(
                  color: AppColors.accentBrown,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
