import 'package:flutter/material.dart';
import 'package:jamup_app/features/booking/pages/booking_detail_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../booking/data/booking_repository.dart';
import '../../booking/models/schedule_item.dart';
import '../../../core/constants/app_colors.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final BookingRepository _repo = BookingRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _loading = true;
  Map<DateTime, List<ScheduleItem>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  // ===============================
  // DATA
  // ===============================

  Future<void> _loadSchedule() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser!;
      final role = (await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single())['role'];

      final bookings = await _repo.getConfirmedSchedule(
        userId: user.id,
        role: role,
      );

      setState(() {
        _events = _groupByDay(bookings);
        _loading = false;
      });
    } catch (e, s) {
      debugPrint('❌ Schedule load error: $e');
      debugPrintStack(stackTrace: s);

      setState(() {
        _loading = false;
      });
    }
  }

  Map<DateTime, List<ScheduleItem>> _groupByDay(
    List<Map<String, dynamic>> bookings,
  ) {
    final Map<DateTime, List<ScheduleItem>> map = {};

    for (final b in bookings) {
      final id = b['id']?.toString();
      final startRaw = b['start_time'];
      final endRaw = b['end_time'];
      final gigs = b['gigs'];

      // 🔒 Skip invalid data safely
      if (id == null || startRaw == null || endRaw == null) {
        debugPrint('⚠️ Skipping invalid booking: $b');
        continue;
      }

      final startTime = DateTime.tryParse(startRaw.toString());
      final endTime = DateTime.tryParse(endRaw.toString());

      if (startTime == null || endTime == null) {
        debugPrint('⚠️ Invalid date format: $b');
        continue;
      }

      final title = gigs?['title']?.toString() ?? 'Untitled Gig';
      final location = gigs?['location']?.toString() ?? 'Unknown Venue';

      final item = ScheduleItem(
        bookingId: id,
        startTime: startTime,
        endTime: endTime,
        title: title,
        location: location,
      );

      final dayKey = DateTime.utc(
        startTime.year,
        startTime.month,
        startTime.day,
      );

      map.putIfAbsent(dayKey, () => []);
      map[dayKey]!.add(item);
    }

    return map;
  }

  List<ScheduleItem> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  // ===============================
  // UI
  // ===============================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primaryGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(
                    child: Text(
                      'No gigs scheduled',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final item = selectedEvents[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.location}\n'
                            '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingDetailPage(
                                  bookingId: item.bookingId,
                                ),
                              ),
                            ).then((_) => _loadSchedule());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
