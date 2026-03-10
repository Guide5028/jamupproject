import 'dart:async';
import 'dart:math';
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
  distance,
}

class GigController extends ChangeNotifier {
  final GigRepository repo;
  GigController(this.repo);

  GigSort sort = GigSort.dateAsc;

  void setSort(GigSort v) {
    sort = v;
    notifyListeners();
  }

  //location for nearby gigs
  double? userLat;
  double? userLng;
  bool isNearbyMode = false;
  int radiusKm = 5;

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

  Future<void> loadNearby({
  double? lat,
  double? lng,
  double radiusKm = 5,
}) async {
  try {
    loading = true;
    notifyListeners();

    if (lat == null || lng == null) {
      if (userLat == null || userLng == null) {
        throw Exception("User location not available");
      }
      lat = userLat;
      lng = userLng;
    }

    userLat = lat;
    userLng = lng;

    final data = await repo.fetchNearbyGigs(
      userLat: lat!,
      userLng: lng!,
      radius: radiusKm.toDouble(),
    );

    // ✅ save gigs first
    gigs = data;

    // ✅ calculate distance
    for (var g in gigs) {
      if (g.latitude != null && g.longitude != null) {
        g.distance = calculateDistance(
          userLat!,
          userLng!,
          g.latitude!,
          g.longitude!,
        );
      }
    }

    isNearbyMode = true;
  } catch (e) {
    error = e.toString();
  } finally {
    loading = false;
    notifyListeners();
  }
}

  Future<void> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      gigs = await repo.fetchAll();
      isNearbyMode = false;
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
      case GigSort.distance:
        out.sort(
            (a, b) => (a.distance ?? 99999).compareTo(b.distance ?? 99999));
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
      searchQuery = v.trim();
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

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371;
    final dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    final dLon = (lon2 - lon1) * (3.141592653589793 / 180);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1 * (3.141592653589793 / 180)) *
            cos(lat2 * (3.141592653589793 / 180)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
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
