import 'package:flutter/material.dart';
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
  String? role;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final user = supabase.auth.currentUser!;

    final me = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    role = me['role'];

    final data = await supabase
        .from('bookings')
        .select('''
          id,
          status,
          start_time,
          end_time,
          musician_id,
          venue_id,
          gigs(title, location)
        ''')
        .eq('id', widget.bookingId)
        .single();

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
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(gig['location']),
            const SizedBox(height: 8),
            Text(
                '${_format(start)} - ${_format(end)}'),
            const SizedBox(height: 12),
            _statusBadge(status),
            const Spacer(),

            /// 🔘 ACTION BUTTONS
            if (status == 'pending' && role == 'venue')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _repo.respondToBooking(
                            bookingId: booking!['id'],
                            status: 'confirmed');
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _repo.respondToBooking(
                            bookingId: booking!['id'],
                            status: 'declined');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),

            if (status == 'confirmed')
              ElevatedButton(
                onPressed: () async {
                  await _repo.cancelBooking(booking!['id']);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                child: const Text('Cancel Booking'),
              ),
          ],
        ),
      ),
    );
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
