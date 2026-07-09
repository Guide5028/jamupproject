import 'dart:async'; // for TimeoutException

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// LocationService
/// ---------------
/// Wraps the `geolocator` and `geocoding` packages and hides their quirks
/// from the rest of the app.
///
/// Design rules we follow here:
///   1. NEVER return a fake position in debug mode by default. The old code
///      forced every debug build to look like it was in Chiang Mai, which
///      broke real GPS testing on physical devices.
///   2. Always surface a LocationStatus so the UI can tell the user why
///      it has no location ("GPS off" vs "permission denied forever" vs
///      "network error"). Returning plain null hides the reason.
///   3. Handle `deniedForever` explicitly — requestPermission() will silently
///      do nothing once the user picks "Don't ask again", so we must send
///      them to the App Settings screen.
class LocationService {
  // ── Manual mock switch ─────────────────────────────────────────
  // Set this to true ONLY when you specifically want to test the UI
  // without real GPS (e.g. running on an emulator with no location set).
  // Unlike kDebugMode, this does NOT auto-activate — so real devices keep
  // using real GPS even in debug builds.
  // TRUE while testing on an emulator whose GPS won't accept `adb emu geo fix`.
  // ⚠️ Set back to FALSE before testing real GPS or shipping — otherwise the
  // app always reports Chiang Mai regardless of the real device location.
  static const bool _useMockLocation = true;
  static const double _mockLat = 18.7883; // Chiang Mai
  static const double _mockLng = 98.9853;

  /// Attempts to get the user's current position.
  /// Returns null when the location is not available; check
  /// [getLocationStatus] or call [getUserLocationWithStatus] to know why.
  static Future<Position?> getUserLocation() async {
    if (_useMockLocation) return _mockPosition();

    try {
      // Step 1 — is GPS / Location services turned on at the OS level?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Step 2 — check current permission.
      var permission = await Geolocator.checkPermission();

      // If we've never asked, ask now. This shows the OS permission dialog.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // "deniedForever" means the user tapped "Don't ask again".
      // requestPermission() will NOT re-prompt. We open the app settings
      // so the user can flip the switch manually.
      // Reference: https://pub.dev/packages/geolocator#android
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return null;
      }

      if (permission == LocationPermission.denied) {
        return null;
      }

      // Step 3 — fetch the position.
      //
      // We use the DEFAULT (fused) provider, which works fine on this emulator
      // — your original code returned a position instantly with it. Forcing the
      // GPS LocationManager made it worse (it has no fix to give, so every
      // request timed out). So: fused last-known first (instant), then a live
      // fused fix as a fallback.
      //
      // 🔎 DIAGNOSTIC: log BOTH providers so we can SEE where the location is.
      //   • fused  = Google Play provider (what the app normally reads)
      //   • gps    = raw Android LocationManager provider
      // Whichever one shows ~18.80, 98.95 is where `adb emu geo fix` landed.
      final fused = await Geolocator.getLastKnownPosition();
      Position? gps;
      try {
        gps = await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: true,
        );
      } catch (_) {
        gps = null;
      }
      print('📍 last-known FUSED: ${fused?.latitude}, ${fused?.longitude}');
      print('📍 last-known GPS:   ${gps?.latitude}, ${gps?.longitude}');

      // Prefer whichever cached fix exists (fused first — it's the reliable one
      // here). Only ask for a live fix if neither provider has anything yet.
      final cached = fused ?? gps;
      if (cached != null) return cached;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      print('📍 fresh fix: ${pos.latitude}, ${pos.longitude}');
      return pos;
    } on TimeoutException catch (_) {
      // GPS didn't respond in time. Last resort: any cached fix at all.
      print('LocationService: getCurrentPosition timed out, trying last-known');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    } catch (e) {
      // Any unexpected error (missing plugin, permission, etc.) -> null.
      print('LocationService.getUserLocation error: $e');
      return null;
    }
  }

  /// Returns a city string like "Chiang Mai, TH".
  /// Falls back to "Thailand" only when the device geocoder gave us
  /// genuinely nothing usable. Otherwise we cascade through several
  /// granularity levels to find the most specific name available.
  ///
  /// Why a cascade?
  /// On many Android devices the built-in Geocoder returns a Placemark
  /// where `locality` is null but `subLocality` or `subAdministrativeArea`
  /// is populated — you'll see this a lot in northern Thailand and rural
  /// areas. The old code only checked locality → subAdministrativeArea
  /// and bailed to "Thailand" too eagerly, which is why the pill kept
  /// showing the country name.
  /// Reference: https://pub.dev/packages/geocoding (Placemark fields)
  static Future<String> getCityName() async {
    final pos = await getUserLocation();
    if (pos == null) return "Thailand";

    try {
      // `placemarkFromCoordinates` uses the device's built-in geocoder
      // on Android (no internet needed on most devices) and Apple's on iOS.
      // It can still fail on some Android devices where Google Play
      // Services are disabled — so we wrap it.
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return "Thailand";

      final p = placemarks.first;
      final country = (p.isoCountryCode ?? "").trim();

      // Cascade most-specific → least-specific. firstWhere() with a
      // generous .isNotEmpty test filters out null AND empty strings.
      final candidates = <String?>[
        p.locality,             // City      e.g. "Chiang Mai"
        p.subLocality,          // District  e.g. "Tha Sala"
        p.subAdministrativeArea,// County    e.g. "Mueang Chiang Mai"
        p.administrativeArea,   // Province  e.g. "Chiang Mai Province"
      ];
      final city = candidates
          .firstWhere(
            (s) => s != null && s.trim().isNotEmpty,
            orElse: () => null,
          )
          ?.trim();

      if (city == null || city.isEmpty) {
        // No city-ish field had data → use country name (not the
        // hard-coded string "Thailand"), or as a last resort the iso code.
        if ((p.country ?? '').trim().isNotEmpty) return p.country!.trim();
        if (country.isNotEmpty) return country;
        return "Thailand";
      }

      return country.isEmpty ? city : "$city, $country";
    } catch (e) {
      print('LocationService.getCityName error: $e');
      return "Thailand";
    }
  }

  // ── Internal helper for the mock flag ──────────────────────────
  static Position _mockPosition() => Position(
        latitude: _mockLat,
        longitude: _mockLng,
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
