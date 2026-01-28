import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/gig.dart';
import '../data/gig_repository.dart';

enum GigSort {
  dateAsc,
  dateDesc,
  newest,
  oldest,
  titleAz,
  titleZa,
  locationAz,
  locationZa,
}

class GigController extends ChangeNotifier {
  final GigRepository repo;
  GigController(this.repo);
  
  GigSort sort = GigSort.dateAsc;

void setSort(GigSort v) {
  sort = v;
  notifyListeners();
}

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

  /// 🔎 Search
  String searchQuery = "";
  Timer? _debounce;

  /* PUBLIC / MUSICIAN SIDE */

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

  /// ✅ Filter + Search + Sort combined
List<Gig> get filtered {
  final q = searchQuery.trim().toLowerCase();

  Iterable<Gig> list = gigs;

  // 1) Genre filter
  if (selectedFilter.isNotEmpty) {
    list = list.where((g) => g.genres.any(
          (gen) => gen.toLowerCase() == selectedFilter.toLowerCase(),
        ));
  }

  // 2) Search filter
  if (q.isNotEmpty) {
    list = list.where((g) {
      final title = g.title.toLowerCase();
      final loc = g.location.toLowerCase();
      final genres = g.genres.join(' ').toLowerCase();
      return title.contains(q) || loc.contains(q) || genres.contains(q);
    });
  }

  // 3) Sort
  final out = list.toList();

  int cmpStr(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  switch (sort) {
    case GigSort.dateAsc:
      out.sort((a, b) => a.date.compareTo(b.date));
      break;
    case GigSort.dateDesc:
      out.sort((a, b) => b.date.compareTo(a.date));
      break;
    case GigSort.newest:
      out.sort((a, b) => b.date.compareTo(a.date));
      break;
    case GigSort.oldest:
      out.sort((a, b) => a.date.compareTo(b.date));
      break;
    case GigSort.titleAz:
      out.sort((a, b) => cmpStr(a.title, b.title));
      break;
    case GigSort.titleZa:
      out.sort((a, b) => cmpStr(b.title, a.title));
      break;
    case GigSort.locationAz:
      out.sort((a, b) => cmpStr(a.location, b.location));
      break;
    case GigSort.locationZa:
      out.sort((a, b) => cmpStr(b.location, a.location));
      break;
  }

  return out;
}


  void toggleFilter(String filter) {
    selectedFilter = (selectedFilter == filter) ? "" : filter;
    notifyListeners();
  }

  /// 🔎 Debounced search input
  void setSearchQuery(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      searchQuery = v;
      notifyListeners();
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    searchQuery = "";
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /* VENUE SIDE */

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
