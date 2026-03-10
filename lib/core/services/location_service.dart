import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Position?> getUserLocation() async {
    if (kDebugMode) {
      return Position(
        latitude: 18.7883,
        longitude: 98.9853,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 1,
        headingAccuracy: 1,
      );
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> getCityName() async {
  final pos = await getUserLocation();
  if (pos == null) return "Thailand";

  final placemarks = await placemarkFromCoordinates(
    pos.latitude,
    pos.longitude,
  );

  if (placemarks.isEmpty) return "Thailand";

  final p = placemarks.first;

  final city = p.locality ?? p.subAdministrativeArea ?? "";
  final country = p.isoCountryCode ?? "";

  if (city.isEmpty) return country;

  return "$city, $country";
}
}
