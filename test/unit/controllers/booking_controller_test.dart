import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/features/booking/controllers/booking_controller.dart';
import 'package:jamup_app/features/booking/data/booking_repository.dart';

class _FakeBookingRepository extends BookingRepository {
  List<Map<String, dynamic>> seedBookings = [];
  List<Map<String, dynamic>> seedSchedule = [];
  bool throwOnLoad = false;
  String? lastRespondedBookingId;
  String? lastRespondedStatus;

  @override
  Future<List<Map<String, dynamic>>> getBookingsForMusician(
      String musicianId) async {
    if (throwOnLoad) throw Exception('boom');
    return seedBookings;
  }

  @override
  Future<List<Map<String, dynamic>>> getBookingsForVenue(
      String venueId) async {
    if (throwOnLoad) throw Exception('boom');
    return seedBookings;
  }

  @override
  Future<List<Map<String, dynamic>>> getConfirmedSchedule({
    required String userId,
    required String role,
  }) async {
    if (throwOnLoad) throw Exception('boom');
    return seedSchedule;
  }

  @override
  Future<void> respondToBooking({
    required String bookingId,
    required String status,
  }) async {
    lastRespondedBookingId = bookingId;
    lastRespondedStatus = status;
  }

  @override
  Future<Map<String, dynamic>> createBookingAndChat({
    required String gigId,
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return {'booking': {}, 'chatId': 'fake-chat-id'};
  }
}

void main() {
  group('BookingController — load happy path', () {
    test('loadBookingsForMusician populates list and clears loading',
        () async {
      final repo = _FakeBookingRepository()
        ..seedBookings = [
          {'id': 'b1', 'status': 'pending'},
          {'id': 'b2', 'status': 'confirmed'},
        ];
      final ctrl = BookingController(repo);

      await ctrl.loadBookingsForMusician('me');

      expect(ctrl.bookings.length, 2);
      expect(ctrl.loading, false);
      expect(ctrl.error, isNull);
    });

    test('loadBookingsForVenue populates list', () async {
      final repo = _FakeBookingRepository()
        ..seedBookings = [{'id': 'v1', 'status': 'pending'}];
      final ctrl = BookingController(repo);

      await ctrl.loadBookingsForVenue('venue-1');

      expect(ctrl.bookings.length, 1);
    });

    test('loadSchedule populates schedule', () async {
      final repo = _FakeBookingRepository()
        ..seedSchedule = [{'id': 's1'}];
      final ctrl = BookingController(repo);

      await ctrl.loadSchedule(userId: 'u', role: 'musician');

      expect(ctrl.schedule.length, 1);
    });
  });

  group('BookingController — load error path', () {
    test('Error from repo lands in `error`, loading=false, list unchanged',
        () async {
      final repo = _FakeBookingRepository()..throwOnLoad = true;
      final ctrl = BookingController(repo);

      await ctrl.loadBookingsForMusician('me');

      expect(ctrl.error, contains('boom'));
      expect(ctrl.loading, false);
      // Existing list (empty) is preserved — never half-populated.
      expect(ctrl.bookings, isEmpty);
    });
  });

  group('BookingController — respondToBooking', () {
    test('Updates status of the matching local row (optimistic UI)',
        () async {
      final repo = _FakeBookingRepository()
        ..seedBookings = [
          {'id': 'b1', 'status': 'pending'},
          {'id': 'b2', 'status': 'pending'},
        ];
      final ctrl = BookingController(repo);
      await ctrl.loadBookingsForMusician('me');

      await ctrl.respondToBooking(bookingId: 'b2', status: 'confirmed');

      // Repository got the call with the right args
      expect(repo.lastRespondedBookingId, 'b2');
      expect(repo.lastRespondedStatus, 'confirmed');

      // Local list was updated in-place, b1 untouched
      final b1 = ctrl.bookings.firstWhere((b) => b['id'] == 'b1');
      final b2 = ctrl.bookings.firstWhere((b) => b['id'] == 'b2');
      expect(b1['status'], 'pending');
      expect(b2['status'], 'confirmed');
    });
  });

  group('BookingController — createBookingForGig', () {
    test('Successful create completes loading without error', () async {
      final ctrl = BookingController(_FakeBookingRepository());

      await ctrl.createBookingForGig(
        gigId: 'g1',
        venueId: 'v1',
        startTime: DateTime(2026, 6, 1, 20),
        endTime: DateTime(2026, 6, 1, 22),
      );

      expect(ctrl.loading, false);
      expect(ctrl.error, isNull);
    });
  });

  group('BookingController — Listener notifications', () {
    test('loadBookingsForMusician fires at least 2 listener notifications',
        () async {
      // Pattern: 1 fire on entering loading=true, 1 fire on exit. If a
      // future refactor reduces these, the UI's "spinner stops on done"
      // contract breaks — a regression we want to catch.
      final ctrl = BookingController(_FakeBookingRepository());
      var count = 0;
      ctrl.addListener(() => count++);

      await ctrl.loadBookingsForMusician('me');

      expect(count, greaterThanOrEqualTo(2));
    });
  });
}
