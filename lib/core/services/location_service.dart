import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getUserLocation() async {
    // 🔥 DEV SAFE MODE
    if (kDebugMode) {
      return Position(
        latitude: 18.7883,   // Chiang Mai
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

    // 🔥 PRODUCTION MODE
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      return null;
    }
  }
}