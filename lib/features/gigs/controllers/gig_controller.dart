import 'package:flutter/material.dart';
import '../../../models/gig.dart';
import '../data/gig_repository.dart';

class GigController extends ChangeNotifier {
  final GigRepository repo;
  GigController(this.repo);

  bool loading = false;
  String? error;
  List<Gig> gigs = [];
  String selectedFilter = "";

  Future<void> loadGigs() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      gigs = await repo.fetchAllGigs();
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  List<Gig> get filtered {
    if (selectedFilter.isEmpty) return gigs;
    return gigs.where((g) {
      return g.genres.any(
        (genre) => genre.toLowerCase() == selectedFilter.toLowerCase(),
      );
    }).toList();
  }

  void toggleFilter(String filter) {
    if (selectedFilter == filter) {
      selectedFilter = "";
    } else {
      selectedFilter = filter;
    }
    notifyListeners();
  }
}
