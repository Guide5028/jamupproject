import 'package:flutter/material.dart';
import 'package:jamup_app/core/constants/app_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../booking/data/booking_repository.dart';
import '../../booking/models/schedule_item.dart';
import '../../booking/pages/booking_detail_page.dart';
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

      final startUtc = DateTime.tryParse(startRaw.toString());
      final endUtc = DateTime.tryParse(endRaw.toString());

      if (startUtc == null || endUtc == null) {
        debugPrint('⚠️ Invalid date format: $b');
        continue;
      }

      // Convert to local time so calendar days match the user's timezone
      final startTime = startUtc.toLocal();
      final endTime = endUtc.toLocal();

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
          // Why a custom Stack with an IconButton instead of an AppBar?
          // We want to preserve the gradient/rounded-bottom header look.
          // Flutter's auto-back-button only appears when there IS an AppBar.
          // No AppBar = no back button. So we add one ourselves and call
          // Navigator.maybePop() — `maybePop` is safer than `pop` because
          // it returns `false` instead of throwing when the route stack is
          // empty (which can happen if this page is ever made the root).
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Top row: back arrow on the left, title centered.
                // The empty SizedBox on the right balances the row so
                // the title stays visually centered.
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.maybePop(context),
                      tooltip: 'Back',
                    ),
                    const Expanded(
                      child: Text(
                        "My Schedule",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                // Month navigation row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month - 1,
                        );
                      }),
                    ),
                    Text(
                      _monthLabel(_focusedDay),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month + 1,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  headerVisible: false,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.white70),
                    defaultTextStyle: TextStyle(color: Colors.white),
                    // A day the user TAPPED gets a solid WHITE circle with dark
                    // text — clearly visible on the gold header (a gold circle
                    // was invisible because the header is the same gold).
                    selectedDecoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.bold,
                    ),
                    // NOTE: we intentionally don't set markerDecoration or
                    // todayDecoration here — both are drawn by the custom
                    // calendarBuilders below so we get full control over how
                    // "has work" and "today" look.
                  ),
                  // calendarBuilders lets us override how individual day cells
                  // are painted. We use it for the two cues you asked for:
                  //   1) a gold dot under any day that has a gig  ("has work")
                  //   2) an outlined ring around today            ("today")
                  calendarBuilders: CalendarBuilders(
                    // ── "Has work" marker ──
                    // table_calendar calls this for every day and passes the
                    // events returned by eventLoader (our _getEventsForDay).
                    // Returning null means "draw nothing"; we only draw a dot
                    // when the day actually has at least one booking.
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      // Green dot = a confirmed gig on this day. Green reads as
                      // "booked" and stands out on the gold header (the old
                      // gold dot was the same colour as the background, so it
                      // was invisible). A thin white ring makes it pop more.
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      );
                    },
                    // ── "Today" ring ──
                    // We draw today as an outlined (not filled) circle so it's
                    // always recognisable as "the day we're on now", even when
                    // the user has selected a different day. If today is also
                    // the selected day, table_calendar uses selectedDecoration
                    // instead, so there's no visual clash.
                    todayBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),

                // ================= LEGEND =================
                // A tiny key so the user understands what the dot and ring
                // mean. Without this, coloured shapes are just decoration —
                // a legend turns them into information.
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Confirmed gig',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 18),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Today',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
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

                      // InkWell wraps the card so the whole row is tappable.
                      // Tapping opens the booking detail (already exists with
                      // confirm/decline/cancel actions).
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
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
                        child: Container(
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
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),

                              // Right chevron hints the row is tappable.
                              const Icon(Icons.chevron_right,
                                  color: AppColors.accentBrown),
                            ],
                          ),
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

  String _monthLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}
