import 'package:flutter/foundation.dart';
import 'search_repository.dart';
import '../../models/musician.dart';
import '../../models/venue.dart';

class SearchController extends ChangeNotifier {
  final SearchRepository repo;
  SearchController(this.repo);

  // STATE
  String query = '';
  String? genre;
  String? musicianType;
  String? venueType;

  bool loading = false;
  List<Musician> musicians = [];
  List<Venue> venues = [];
  String? error;

  Future<void> fetchMusicians() async {
    loading = true; error = null; notifyListeners();
    try {
      musicians = await repo.searchMusicians(
        query: query, genre: genre, type: musicianType,
      );
    } catch (e) { error = e.toString(); }
    loading = false; notifyListeners();
  }

  Future<void> fetchVenues() async {
    loading = true; error = null; notifyListeners();
    try {
      venues = await repo.searchVenues(
        query: query, venueType: venueType,
      );
    } catch (e) { error = e.toString(); }
    loading = false; notifyListeners();
  }
}
