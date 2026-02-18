class ScheduleItem {
  final String bookingId;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final String location;

  ScheduleItem({
    required this.bookingId,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.location,
  });
}
