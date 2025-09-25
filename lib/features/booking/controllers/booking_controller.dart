import 'package:flutter/material.dart';
import '../data/booking_repository.dart';

class BookingController extends ChangeNotifier {
  final BookingRepository repo;
  BookingController(this.repo);

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> bookings = [];

  /// Load bookings for a specific musician
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

  /// Load bookings for a specific venue
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

  /// Create a new booking
  Future<void> createBooking({
    required String gigId,
    required String musicianId,
    required String venueId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await repo.createBooking(
        gigId: gigId,
        musicianId: musicianId,
        venueId: venueId,
      );
      // Refresh list if needed
      await loadBookingsForMusician(musicianId);
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await repo.updateBookingStatus(
        bookingId: bookingId,
        status: status,
      );

      // Update in local state (optional optimization)
      final index = bookings.indexWhere((b) => b['id'] == bookingId);
      if (index != -1) {
        bookings[index]['status'] = status;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
