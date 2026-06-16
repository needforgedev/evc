import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Dubai (Downtown / Business Bay) — the EVC service-region center. Every map
/// opens here, so the app always shows Dubai regardless of where the device is.
const LatLng kDubaiCenter = LatLng(25.2048, 55.2708);

/// Rough UAE bounding box (lat 22–26.5, lng 51–56.5).
const double _uaeMinLat = 22.0;
const double _uaeMaxLat = 26.5;
const double _uaeMinLng = 51.0;
const double _uaeMaxLng = 56.5;

/// True when [lat]/[lng] fall inside the UAE service region.
bool isInServiceRegion(double lat, double lng) =>
    lat >= _uaeMinLat &&
    lat <= _uaeMaxLat &&
    lng >= _uaeMinLng &&
    lng <= _uaeMaxLng;

/// Device location, **clamped to the EVC service region**.
///
/// ### The India-while-developing problem
/// The app targets the UAE, but it's being built/tested from India. Real device
/// GPS honestly reports *India* (or, on a simulator, its default like Apple
/// Park, California) — never Dubai. That would put "my location" and the live
/// driver dot thousands of km away from the Dubai map.
///
/// ### The fallback
/// [current] uses the real GPS fix **only when it's inside the UAE**. In every
/// other case — permission denied, location services off, an error, or a fix
/// outside the service region (e.g. India) — it returns [kDubaiCenter]. So
/// during development everything behaves as if the device were in Dubai, with
/// **zero code change** when the very same build later runs on the ground in the
/// UAE (there the real fix is inside the box, so it's used as-is).
///
/// To test with a *moving* real fix during dev, set the simulator's location to
/// Dubai (iOS Simulator → Features → Location → Custom: 25.2048, 55.2708;
/// Android emulator → Extended controls → Location) — then the fix is inside the
/// box and used directly.
class EvcLocation {
  const EvcLocation._();

  /// Best-effort current position, guaranteed to be within the UAE.
  static Future<LatLng> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return kDubaiCenter;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return kDubaiCenter;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!isInServiceRegion(pos.latitude, pos.longitude)) {
        return kDubaiCenter; // dev fallback — outside the UAE (e.g. India)
      }
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return kDubaiCenter;
    }
  }
}
