import 'package:flutter/material.dart';
import '../../../models/gig.dart';
import '../data/gig_repository.dart';

class GigController extends ChangeNotifier {
  final GigRepository repo;
  GigController(this.repo);

  bool loading = false;
  String? error;

  /// Public gigs (Gigs page)
  List<Gig> gigs = [];

  /// Home page lists
  List<Gig> upcoming = [];
  List<Gig> all = [];

  /// Venue-owned gigs
  List<Gig> myGigs = [];

  /// Genre filter
  String selectedFilter = "";

  /* PUBLIC / MUSICIAN SIDE */

  /// Load gigs for public browsing (optional genre)
  Future<void> loadGigs({String? genre}) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      gigs = await repo.fetchAll(genre: genre);
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  /// Load data for Home page
  Future<void> loadForHome() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      upcoming = await repo.fetchUpcoming(limit: 10);
      all = await repo.fetchAll();
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  /// Apply genre filter on public gigs
  List<Gig> get filtered {
    if (selectedFilter.isEmpty) return gigs;
    return gigs
        .where((g) =>
            g.genres.any((gen) =>
                gen.toLowerCase() == selectedFilter.toLowerCase()))
        .toList();
  }

  void toggleFilter(String filter) {
    selectedFilter = (selectedFilter == filter) ? "" : filter;
    notifyListeners();
  }

  /* VENUE SIDE */

  /// Load gigs created by the logged-in venue
  Future<void> loadMyGigs(String venueId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      myGigs = await repo.fetchMyGigs(venueId);
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }
}
