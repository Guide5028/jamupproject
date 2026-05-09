// ST-25 — Venue Declines a Booking Request
//
// Pumps VenueBookingsPage with a fake controller seed and verifies that
// tapping Decline changes the status badge to "declined" and removes the
// Confirm / Decline buttons, while keeping the Chat button visible.

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
          'title': 'Jazz Night',
          'location': 'Bangkok',
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

// ── Test ───────────────────────────────────────────────────────────────────

void main() {
  group('ST-25 — Venue Declines a Booking Request', () {
    late _FakeBookingRepo fakeRepo;

    setUp(() => fakeRepo = _FakeBookingRepo());

    Widget _buildPage() {
      return ChangeNotifierProvider(
        create: (_) =>
            BookingController(fakeRepo)..loadBookingsForVenue('venue1'),
        child: const MaterialApp(home: VenueBookingsPage()),
      );
    }

    testWidgets('Pending booking shows Confirm and Decline buttons',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('pending'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('Tapping Decline calls repo with status "declined"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Decline'));
      await tester.pump(const Duration(seconds: 1));

      expect(fakeRepo.lastRespondedId, 'b1');
      expect(fakeRepo.lastRespondedStatus, 'declined');
    });

    testWidgets('After decline, status badge updates to "declined"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Decline'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('declined'), findsOneWidget,
          reason: 'Status badge must change to declined after tapping Decline');
    });

    testWidgets('After decline, Confirm and Decline buttons disappear',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Decline'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Confirm'), findsNothing,
          reason: 'Confirm button must be gone after booking is decided');
      expect(find.text('Decline'), findsNothing,
          reason: 'Decline button must be gone after booking is decided');
    });

    testWidgets('Chat button remains visible after decline', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Decline'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Chat'), findsOneWidget,
          reason: 'Chat must remain available after a decline decision');
    });
  });
}
