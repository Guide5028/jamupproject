// ST-15 — Venue Confirms a Booking Request
//
// Pumps VenueBookingsPage with a fake controller seeded with a pending
// booking and verifies that tapping "Confirm" calls the repo with status
// "confirmed" and updates the status badge.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jamup_app/features/booking/controllers/booking_controller.dart';
import 'package:jamup_app/features/booking/data/booking_repository.dart';
import 'package:jamup_app/features/booking/pages/venue_bookings_page.dart';

// ── Fake repository ────────────────────────────────────────────────────────

class _FakeBookingRepo extends BookingRepository {
  String? lastRespondedId;
  String? lastRespondedStatus;

  @override
  Future<List<Map<String, dynamic>>> getBookingsForVenue(
      String venueId) async {
    return [
      {
        'id': 'b1',
        'status': 'pending',
        'gigs': {
          'title': 'Sunday Acoustic Set',
          'location': 'Phuket',
          'date': DateTime.now().toIso8601String(),
          'image_url': '',
        },
        'users': {'name': 'Test Musician', 'avatar_url': ''},
      },
    ];
  }

  @override
  Future<void> respondToBooking({
    required String bookingId,
    required String status,
  }) async {
    lastRespondedId = bookingId;
    lastRespondedStatus = status;
  }

  @override
  Future<String> getChatIdForBooking(String bookingId) async => 'chat-1';
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _buildPage(_FakeBookingRepo repo) {
  return ChangeNotifierProvider(
    create: (_) =>
        BookingController(repo)..loadBookingsForVenue('venue1'),
    child: const MaterialApp(home: VenueBookingsPage()),
  );
}

void main() {
  group('ST-15 — Venue Confirms a Booking Request', () {
    late _FakeBookingRepo fakeRepo;

    setUp(() => fakeRepo = _FakeBookingRepo());

    testWidgets('Pending booking shows Confirm button', (tester) async {
      await tester.pumpWidget(_buildPage(fakeRepo));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Confirm'), findsOneWidget,
          reason: 'Pending booking must show a Confirm button');
    });

    testWidgets('Tapping Confirm calls repo with status "confirmed"',
        (tester) async {
      await tester.pumpWidget(_buildPage(fakeRepo));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Confirm'));
      await tester.pump(const Duration(seconds: 1));

      expect(fakeRepo.lastRespondedStatus, 'confirmed',
          reason: 'Tapping Confirm must call repo with "confirmed" status');
      expect(fakeRepo.lastRespondedId, 'b1',
          reason: 'Confirm must pass the correct booking ID');
    });

    testWidgets('After confirm, status badge updates to confirmed',
        (tester) async {
      await tester.pumpWidget(_buildPage(fakeRepo));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Confirm'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('confirmed'), findsOneWidget,
          reason: 'Status badge must update to "confirmed" after confirming');
    });

    testWidgets('After confirm, Confirm and Decline buttons disappear',
        (tester) async {
      await tester.pumpWidget(_buildPage(fakeRepo));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Confirm'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Confirm'), findsNothing,
          reason: 'Confirm button must disappear after the booking is confirmed');
      expect(find.text('Decline'), findsNothing,
          reason: 'Decline button must disappear after the booking is confirmed');
    });
  });
}
