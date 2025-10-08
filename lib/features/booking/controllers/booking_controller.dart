import 'package:flutter/material.dart';
import '../data/booking_repository.dart';

class BookingController extends ChangeNotifier {
  final BookingRepository repo;
  BookingController(this.repo);

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> bookings = [];

  Future<void> loadBookingsForMusician(String musicianId) async {
    loading = true; error = null; notifyListeners();
    try {
      bookings = await repo.getBookingsForMusician(musicianId);
    } catch (e) {
      error = e.toString();
    }
    loading = false; notifyListeners();
  }

  Future<void> loadBookingsForVenue(String venueId) async {
    loading = true; error = null; notifyListeners();
    try {
      bookings = await repo.getBookingsForVenue(venueId);
    } catch (e) {
      error = e.toString();
    }
    loading = false; notifyListeners();
  }

  Future<void> createBooking({
    required String gigId,
    required String musicianId,
    required String venueId,
  }) async {
    loading = true; error = null; notifyListeners();
    try {
      await repo.createBooking(gigId: gigId, musicianId: musicianId, venueId: venueId);
      await loadBookingsForMusician(musicianId);
    } catch (e) {
      error = e.toString();
    }
    loading = false; notifyListeners();
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await repo.updateBookingStatus(bookingId: bookingId, status: status);
      final idx = bookings.indexWhere((b) => b['id'] == bookingId);
      if (idx != -1) {
        bookings[idx]['status'] = status;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
