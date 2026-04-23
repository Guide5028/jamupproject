import 'package:flutter/material.dart';

class FilterState extends ChangeNotifier {
  final Set<String> genres = {};
  final Set<String> types = {};
  final Set<String> locations = {};
  final Set<String> prices = {};

  bool get genreActive => genres.isNotEmpty;
  bool get typeActive => types.isNotEmpty;
  bool get locationActive => locations.isNotEmpty;
  bool get priceActive => prices.isNotEmpty;

  bool get hasActive =>
      genres.isNotEmpty ||
      types.isNotEmpty ||
      locations.isNotEmpty ||
      prices.isNotEmpty;

  void toggleGenre(String g) {
    if (genres.contains(g)) {
      genres.remove(g);
    } else {
      genres.add(g);
    }
    notifyListeners();
  }

  void toggleType(String t) {
    if (types.contains(t)) {
      types.remove(t);
    } else {
      types.add(t);
    }
    notifyListeners();
  }

  void toggleLocation(String l) {
    if (locations.contains(l)) {
      locations.remove(l);
    } else {
      locations.add(l);
    }
    notifyListeners();
  }

  void togglePrice(String p) {
    if (prices.contains(p)) {
      prices.remove(p);
    } else {
      prices.add(p);
    }
    notifyListeners();
  }

  void removeGenre(String g) {
    genres.remove(g);
    notifyListeners();
  }

  void clear() {
    genres.clear();
    types.clear();
    locations.clear();
    prices.clear();
    notifyListeners();
  }
}
