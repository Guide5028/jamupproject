import 'dart:async';
import 'dart:math';
// foundation.dart already provides setEquals AND ChangeNotifier — no need
// to also import material.dart in a pure controller. Leaner imports = faster
// IDE indexing and less coupling between layers.
import 'package:flutter/foundation.dart';

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
  double radiusKm = 25;

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
  Set<String> selectedGenres = {};

  /// Type filter (maps to gig.roleNeeded — Singer, Guitarist, DJ, Band, ...)
  /// Why "Type" instead of "Role"? The pill in the UI says "Type" because
  /// from a venue's discovery perspective ("what kind of musician is this
  /// gig for?") that word reads more naturally to non-engineers.
  Set<String> selectedTypes = {};

  /// Location filter — free-text match against gig.location, case insensitive.
  /// We don't switch to lat/lng-based location filtering here because the
  /// UI presents bucket choices ("Bangkok" / "Chiang Mai"), and string
  /// matching is correct for that bucket model. Geo filtering is a
  /// separate feature ("Nearby"), already handled via the RPC.
  Set<String> selectedLocations = {};

  /// Price-bucket filter — strings like "<3000", "3000-10000", "10000+".
  /// Stored as the same labels the bottom sheet shows so we don't have
  /// to translate twice. Parsed on-the-fly inside `filtered`.
  Set<String> selectedPrices = {};

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
  ///
  /// Order of filtering is deliberate:
  ///   1) genre  → smallest-first set; cheapest predicate
  ///   2) type   (role_needed)
  ///   3) location (string contains)
  ///   4) price  (bucket parse)
  ///   5) free-text search across title/location/genres
  ///   6) sort
  /// We chain `.where()` so each filter shrinks the iterable lazily —
  /// no intermediate List allocation, no wasted work.
  List<Gig> get filtered {
    final q = searchQuery.trim().toLowerCase();

    Iterable<Gig> list = gigs;

    // 1) Genre filter
    if (selectedGenres.isNotEmpty) {
      list = list.where((g) => g.genres.any(
            (gen) => selectedGenres.any(
              (s) =>
                  gen.toLowerCase().contains(s.toLowerCase()) ||
                  s.toLowerCase().contains(gen.toLowerCase()),
            ),
          ));
    }

    // 2) Type filter — match against roleNeeded. "Any" or "" never
    //    survives the active-filter check, so empty selectedTypes is fine.
    if (selectedTypes.isNotEmpty) {
      list = list.where((g) {
        final r = g.roleNeeded.toLowerCase();
        return selectedTypes.any((t) => r == t.toLowerCase());
      });
    }

    // 3) Location filter — case-insensitive contains. A user picking
    //    "Bangkok" should also match "Saxophone Pub, Bangkok" etc.
    if (selectedLocations.isNotEmpty) {
      list = list.where((g) {
        final loc = g.location.toLowerCase();
        return selectedLocations.any((s) => loc.contains(s.toLowerCase()));
      });
    }

    // 4) Price filter — bucket logic. We use `payment` (what the venue
    //    pays the musician) since that's the meaningful number for both
    //    sides of the marketplace. Null payment is treated as "skip".
    if (selectedPrices.isNotEmpty) {
      list = list.where((g) {
        final p = g.payment;
        if (p == null) return false;
        return selectedPrices.any((bucket) => _matchesPriceBucket(p, bucket));
      });
    }

    // 5) Search filter
    if (q.isNotEmpty) {
      list = list.where((g) {
        final title = g.title.toLowerCase();
        final loc = g.location.toLowerCase();
        final genres = g.genres.join(' ').toLowerCase();
        return title.contains(q) || loc.contains(q) || genres.contains(q);
      });
    }

    // 6) Sort
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

  void toggleFilter(String genre) {
    if (selectedGenres.contains(genre)) {
      selectedGenres.remove(genre);
    } else {
      selectedGenres.add(genre);
    }
    notifyListeners();
  }

  void setGenreFilters(Set<String> genres) {
    // IMPORTANT: only notify listeners if the value actually changed.
    // Without this guard, every rebuild that calls this function would
    // fire notifyListeners() → trigger another rebuild → infinite loop.
    // setEquals() comes from flutter/foundation and checks Set equality
    // (regular == on Set returns false even if both sets contain the
    // same elements, because == on collections compares references).
    if (setEquals(selectedGenres, genres)) return;

    selectedGenres = {...genres};
    notifyListeners();
  }

  void setTypeFilters(Set<String> types) {
    if (setEquals(selectedTypes, types)) return;
    selectedTypes = {...types};
    notifyListeners();
  }

  void setLocationFilters(Set<String> locations) {
    if (setEquals(selectedLocations, locations)) return;
    selectedLocations = {...locations};
    notifyListeners();
  }

  void setPriceFilters(Set<String> prices) {
    if (setEquals(selectedPrices, prices)) return;
    selectedPrices = {...prices};
    notifyListeners();
  }

  /// Parses a UI bucket label like "<฿3000" or "฿3000-฿10000" or "฿10000+"
  /// and tests whether `price` falls inside it. Done as a pure function
  /// so the rules are visible in one place — change the labels in the
  /// bottom sheet, and the parser keeps working.
  bool _matchesPriceBucket(double price, String bucket) {
    final clean = bucket.replaceAll('฿', '').replaceAll(',', '').trim();
    if (clean.startsWith('<')) {
      final upper = double.tryParse(clean.substring(1).trim());
      return upper != null && price < upper;
    }
    if (clean.endsWith('+')) {
      final lower =
          double.tryParse(clean.substring(0, clean.length - 1).trim());
      return lower != null && price >= lower;
    }
    if (clean.contains('-')) {
      final parts = clean.split('-');
      final lower = double.tryParse(parts[0].trim());
      final upper = double.tryParse(parts[1].trim());
      return lower != null &&
          upper != null &&
          price >= lower &&
          price <= upper;
    }
    return false;
  }

  void setNearbyRadius(double km) {
    radiusKm = km;
    // Reload with new radius using saved coordinates
    if (userLat != null && userLng != null) {
      loadNearby(lat: userLat, lng: userLng, radiusKm: km);
    }
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
