// ============================================================================
// schedule_item_test.dart
// ============================================================================
// Why this file exists (teaching note for Guide):
//
//   ScheduleItem is a value object — a plain data carrier. Tests for
//   value objects look trivial, but they serve as REGRESSION GUARDS:
//   if anyone deletes a field tomorrow, the failing test narrates WHY
//   the field matters (used by SchedulePage to build calendar tiles).
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/features/booking/models/schedule_item.dart';

void main() {
  group('ScheduleItem', () {
    test('Constructor stores all required fields verbatim', () {
      final start = DateTime(2026, 6, 15, 20, 0);
      final end = DateTime(2026, 6, 15, 22, 0);

      final item = ScheduleItem(
        bookingId: 'booking-123',
        startTime: start,
        endTime: end,
        title: 'Friday Jazz Night',
        location: 'Porjai Bar',
      );

      expect(item.bookingId, 'booking-123');
      expect(item.startTime, start);
      expect(item.endTime, end);
      expect(item.title, 'Friday Jazz Night');
      expect(item.location, 'Porjai Bar');
    });

    test('Two items with identical fields are NOT equal by default', () {
      // Pinning current behaviour: ScheduleItem doesn't override `==`,
      // so two distinct instances are different by reference. If you
      // later add value-equality, change this test rather than silently
      // letting it pass — it'll fail loudly and force the conscious update.
      final start = DateTime(2026, 6, 15);
      final end = DateTime(2026, 6, 15, 23);

      final a = ScheduleItem(
        bookingId: '1', startTime: start, endTime: end,
        title: 't', location: 'l',
      );
      final b = ScheduleItem(
        bookingId: '1', startTime: start, endTime: end,
        title: 't', location: 'l',
      );

      expect(a == b, false);
      expect(identical(a, b), false);
    });

    test('Duration between start and end is computable for tile rendering',
        () {
      final item = ScheduleItem(
        bookingId: '1',
        startTime: DateTime(2026, 6, 15, 20, 0),
        endTime: DateTime(2026, 6, 15, 22, 30),
        title: 't',
        location: 'l',
      );
      expect(
        item.endTime.difference(item.startTime),
        const Duration(hours: 2, minutes: 30),
      );
    });
  });
}
