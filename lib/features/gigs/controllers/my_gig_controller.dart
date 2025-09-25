import 'package:flutter/material.dart';
import '../data/my_gig_repository.dart';

class MyGigsController extends ChangeNotifier {
  final MyGigsRepository repo;
  MyGigsController(this.repo);

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> gigs = [];

  Future<void> loadMyGigs(String venueId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      gigs = await repo.fetchMyGigs(venueId);
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> updateBooking({
    required String bookingId,
    required String chatId,
    required String status,
  }) async {
    try {
      await repo.updateBookingStatus(bookingId: bookingId, status: status);
      await repo.insertSystemMessage(chatId, status);

      // Update local state
      for (final gig in gigs) {
        for (final req in gig['bookings'] ?? []) {
          if (req['id'] == bookingId) {
            req['status'] = status;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
