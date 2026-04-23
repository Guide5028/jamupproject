import 'package:flutter/material.dart';
import 'package:jamup_app/core/constants/app_fonts.dart';
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
  String? _error;

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
        _error = e.toString();
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.accentBrown, size: 32),
              const SizedBox(height: 8),
              Text('Could not load schedule.',
                  style: AppFonts.textTheme.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loading = true;
                  });
                  _loadSchedule();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold),
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ================= HEADER CALENDAR =================
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "My Schedule",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  headerVisible: false,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                    defaultTextStyle: const TextStyle(color: Colors.white),
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
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= SELECTED DATE LABEL =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatFullDate(_selectedDay ?? _focusedDay),
                style: AppFonts.textTheme.headlineMedium,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ================= EVENT LIST =================
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      'No gigs scheduled',
                      style: AppFonts.textTheme.bodyMedium?.copyWith(color: AppColors.accentBrown),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final item = selectedEvents[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accentBrown.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            // TIME COLUMN
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTime(item.startTime),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(item.endTime),
                                  style: const TextStyle(
                                      color: AppColors.accentBrown),
                                ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // EVENT INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.location,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  String _formatFullDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
