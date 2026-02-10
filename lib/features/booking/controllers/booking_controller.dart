import 'package:flutter/material.dart';
import '../data/booking_repository.dart';

class BookingController extends ChangeNotifier {
  final BookingRepository repo;
  BookingController(this.repo);

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> schedule = [];

  Future<void> loadSchedule({
    required String userId,
    required String role,
  }) async {
    loading = true;
    notifyListeners();

    try {
      schedule = await repo.getConfirmedSchedule(
        userId: userId,
        role: role,
      );
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> loadBookingsForMusician(String musicianId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      bookings = await repo.getBookingsForMusician(musicianId);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadBookingsForVenue(String venueId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      bookings = await repo.getBookingsForVenue(venueId);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  // ✅ NEW: venue confirm/decline
  Future<void> respondToBooking({
    required String bookingId,
    required String status, // confirmed / declined
  }) async {
    error = null;
    notifyListeners();
    try {
      await repo.respondToBooking(bookingId: bookingId, status: status);
      final idx = bookings.indexWhere((b) => b['id'].toString() == bookingId);
      if (idx != -1) {
        bookings[idx]['status'] = status;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createBookingForGig({
    required String gigId,
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await repo.createBookingAndChat(
        gigId: gigId,
        venueId: venueId,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }
}
