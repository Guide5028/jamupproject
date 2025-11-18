import 'package:flutter/material.dart';
import '../../../models/gig.dart';
import '../data/gig_repository.dart';

class GigController extends ChangeNotifier {
  final GigRepository repo;
  GigController(this.repo);

  bool loading = false;
  String? error;

  // List used on the Gigs page (optionally filtered)
  List<Gig> gigs = [];

  // Lists for Home page
  List<Gig> upcoming = [];
  List<Gig> all = [];

  String selectedFilter = "";

  /// Load for Gigs page (optionally by genre)
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

  /// Load both lists for Home page without Future.wait typing pain
  Future<void> loadForHome() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      upcoming = await repo.fetchUpcoming(limit: 10);
      all = await repo.fetchAll(); // you can add a location filter later
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  List<Gig> get filtered {
    if (selectedFilter.isEmpty) return gigs;
    return gigs.where((g) =>
        g.genres.any((gen) => gen.toLowerCase() == selectedFilter.toLowerCase()))
      .toList();
  }

  void toggleFilter(String filter) {
    selectedFilter = (selectedFilter == filter) ? "" : filter;
    notifyListeners();
  }
}
