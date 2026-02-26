import 'package:flutter/material.dart';
import 'package:jamup_app/features/messages/pages/chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../booking/data/booking_repository.dart';

class BookingDetailPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final supabase = Supabase.instance.client;
  final BookingRepository _repo = BookingRepository();

  Map<String, dynamic>? booking;

  bool _loading = true;
  bool _actionLoading = false;
  String? role;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final user = supabase.auth.currentUser!;
    bool _canReview = false;
    bool _alreadyReviewed = false;
    final me =
        await supabase.from('users').select('role').eq('id', user.id).single();

    role = me['role'];

    final data = await supabase.from('bookings').select('''
  id,
  status,
  start_time,
  end_time,
  musician_id,
  venue_id,
  musicians:users!bookings_musician_id_fkey(name, avatar_url),
  venues:users!bookings_venue_id_fkey(name, avatar_url),
  gigs(title, location)
''').eq('id', widget.bookingId).single();

    setState(() {
      booking = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = booking!['status'];
    final gig = booking!['gigs'];
    final start = DateTime.parse(booking!['start_time']);
    final end = DateTime.parse(booking!['end_time']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gig['title'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(gig['location']),
            const SizedBox(height: 8),
            Text('${_format(start)} - ${_format(end)}'),
            const SizedBox(height: 12),
            _statusBadge(status),
            const Spacer(),

            /// 🔘 ACTION BUTTONS
            if (status == 'pending' && role == 'venue')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _actionLoading
                          ? null
                          : () => _handleAction(() => _repo.respondToBooking(
                                bookingId: booking!['id'],
                                status: 'confirmed',
                              )),
                      child: _actionLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _actionLoading
                          ? null
                          : () => _handleAction(() => _repo.respondToBooking(
                                bookingId: booking!['id'],
                                status: 'declined',
                              )),
                      child: _actionLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Decline'),
                    ),
                  ),
                ],
              ),

            ElevatedButton(
              onPressed: () async {
                final chatId = await _repo.getChatIdForBooking(booking!['id']);

                if (chatId == null) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      chatId: chatId,
                      name: '',
                      avatar: '',
                    ),
                  ),
                );
              },
              child: const Text('Open Chat'),
            ),

            if (status == 'confirmed')
              ElevatedButton(
                onPressed: _actionLoading
                    ? null
                    : () => _handleAction(
                          () => _repo.cancelBooking(booking!['id']),
                        ),
                child: _actionLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancel Booking'),
              ),
  //             if (_canReview && !_alreadyReviewed)
  // ElevatedButton(
  //   onPressed: () {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => ReviewPage(
  //           bookingId: booking!['id'],
  //           reviewedUserId: role == 'venue'
  //               ? booking!['musician_id']
  //               : booking!['venue_id'],
  //         ),
  //       ),
  //     );
  //   },
  //   child: const Text('Leave Review'),
  // ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    if (_actionLoading) return;

    setState(() => _actionLoading = true);

    try {
      await action();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'declined':
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _format(DateTime t) {
    return '${t.day}/${t.month}/${t.year} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}
