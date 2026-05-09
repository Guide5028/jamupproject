// ============================================================================
// booking_model_test.dart
// ============================================================================
// Why this file exists (teaching note for Guide):
//
//   The Booking class has BOTH fromJson and toJson, so we can test
//   "round-trip parsing": serialize a Booking, parse it back, and verify
//   nothing was lost. Round-trip tests are powerful because they pin
//   the SHAPE of your DTO — a single dropped field causes a failure.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/models/booking.dart';

Booking _sample() => Booking(
      id: 'b-001',
      gigId: 'g-100',
      musicianId: 'm-200',
      venueId: 'v-300',
      status: 'pending',
      createdAt: DateTime.utc(2026, 4, 25, 10, 30),
      updatedAt: DateTime.utc(2026, 4, 25, 11, 45),
      chatId: 'c-400',
    );

void main() {
  group('Booking Model', () {
    test('Constructor stores all required fields', () {
      final b = _sample();
      expect(b.id, 'b-001');
      expect(b.gigId, 'g-100');
      expect(b.musicianId, 'm-200');
      expect(b.venueId, 'v-300');
      expect(b.status, 'pending');
      expect(b.chatId, 'c-400');
    });

    test('status field is mutable (used by respondToBooking optimistic UI)',
        () {
      // The controller mutates `bookings[idx]['status']` after a confirm
      // / decline. Testing this here documents that `status` is a
      // mutable field by design.
      final b = _sample();
      b.status = 'confirmed';
      expect(b.status, 'confirmed');
    });

    test('toJson produces ISO-8601 timestamps with snake_case keys', () {
      final json = _sample().toJson();
      expect(json['created_at'], '2026-04-25T10:30:00.000Z');
      expect(json['updated_at'], '2026-04-25T11:45:00.000Z');
    });

    test('fromJson + toJson round-trips cleanly', () {
      final original = _sample();
      final restored = Booking.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.gigId, original.gigId);
      expect(restored.musicianId, original.musicianId);
      expect(restored.venueId, original.venueId);
      expect(restored.status, original.status);
      expect(restored.chatId, original.chatId);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });
  });
}
