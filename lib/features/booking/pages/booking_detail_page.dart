import 'package:flutter/material.dart';
import 'package:jamup_app/features/messages/pages/chat_page.dart';
import 'package:jamup_app/features/reviews/pages/review_page.dart';
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
  String? _loadError;
  bool _canReview = false;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Not logged in");

      final me = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

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

      final status = data['status'] as String? ?? '';
      final endTime = DateTime.tryParse(data['end_time'] ?? '') ?? DateTime.now();
      final canReview = status == 'confirmed' && endTime.isBefore(DateTime.now());
      final alreadyReviewed = canReview
          ? await _repo.hasReviewed(bookingId: widget.bookingId)
          : false;

      setState(() {
        booking = data;
        _canReview = canReview;
        _alreadyReviewed = alreadyReviewed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details'), backgroundColor: AppColors.background),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadBooking,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
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
                // Capture Navigator BEFORE the async gap so we never need
                // `context` after the await. This is the canonical pattern
                // the analyzer accepts — it can prove safety without
                // tracing whether `mounted` and `context` are related.
                final navigator = Navigator.of(context);
                final chatId = await _repo.getChatIdForBooking(booking!['id']);

                if (chatId == null) return;
                if (!mounted) return;

                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      chatId: chatId,
                      name: '',
                      avatar: '',
                      otherUserId: '',
                      isVenue: role == 'venue',
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
            if (_canReview && !_alreadyReviewed)
              ElevatedButton.icon(
                icon: const Icon(Icons.star_outline, color: Colors.white),
                label: const Text(
                  'Leave a Review',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final reviewedUserId = role == 'venue'
                      ? booking!['musician_id'] as String
                      : booking!['venue_id'] as String;
                  final reviewedName = role == 'venue'
                      ? (booking!['musicians']?['name'] as String? ?? 'Musician')
                      : (booking!['venues']?['name'] as String? ?? 'Venue');

                  final submitted = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewPage(
                        bookingId: booking!['id'] as String,
                        reviewedUserId: reviewedUserId,
                        reviewedUserName: reviewedName,
                      ),
                    ),
                  );
                  if (submitted == true && mounted) {
                    setState(() => _alreadyReviewed = true);
                  }
                },
              ),
            if (_canReview && _alreadyReviewed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text('You already reviewed this booking',
                        style: TextStyle(
                            color: Colors.green.shade700, fontSize: 13)),
                  ],
                ),
              ),
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
      // Same guard as Navigator.push: ScaffoldMessenger.of(context) walks
      // up the widget tree, which is undefined behaviour after dispose.
      if (!mounted) return;
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
