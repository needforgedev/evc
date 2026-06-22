import 'dart:math' as math;

import 'package:evc_core/evc_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'evc_location.dart';

/// A road route between two points: the polyline to draw plus real
/// distance/drive-time from the Directions API.
class EvcRoute {
  const EvcRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    required this.isReal,
  });

  /// Decoded polyline (pickup → destination). At minimum the two endpoints.
  final List<LatLng> points;
  final double distanceKm;
  final int durationMin;

  /// True when this came from the Directions API; false for the straight-line
  /// fallback (no key / API disabled / request failed / offline).
  final bool isReal;
}

/// Google Directions wrapper. Returns a real road route when available, and a
/// graceful straight-line fallback otherwise so the map always has something to
/// draw.
///
/// Routes through the `maps-proxy` Supabase edge function so the Google key
/// stays server-side (PRD #5) — never shipped in the client.
class EvcDirections {
  const EvcDirections._();

  static Future<EvcRoute> route(LatLng origin, LatLng destination) async {
    final straight = _straightLine(origin, destination);
    if (!EvcSupabase.isReady) return straight;

    try {
      final res = await EvcSupabase.client.functions.invoke('maps-proxy', body: {
        'op': 'directions',
        'origin': {'lat': origin.latitude, 'lng': origin.longitude},
        'destination': {'lat': destination.latitude, 'lng': destination.longitude},
      });
      final data = res.data as Map<String, dynamic>?;
      final gStatus = (data?['status'] as num?)?.toInt() ?? 0;
      final body = data?['body'] as Map<String, dynamic>?;
      if (gStatus != 200 || body == null) return straight;
      // Routes API (New) shape: routes[].distanceMeters / duration ("123s") /
      // polyline.encodedPolyline.
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return straight;
      final r0 = routes.first as Map<String, dynamic>;
      final meters = (r0['distanceMeters'] as num?)?.toDouble();
      final durStr = r0['duration'] as String?; // e.g. "1234s"
      final seconds =
          durStr == null ? null : int.tryParse(durStr.replaceAll('s', ''));
      final encoded =
          (r0['polyline'] as Map<String, dynamic>?)?['encodedPolyline'] as String?;

      final pts = encoded == null || encoded.isEmpty
          ? [origin, destination]
          : decodePolyline(encoded);
      return EvcRoute(
        points: pts,
        distanceKm: meters == null ? straight.distanceKm : meters / 1000.0,
        durationMin: seconds == null
            ? straight.durationMin
            : (seconds / 60).round().clamp(1, 1 << 30),
        isReal: true,
      );
    } catch (_) {
      return straight;
    }
  }

  static EvcRoute _straightLine(LatLng a, LatLng b) {
    final km = _haversineKm(a.latitude, a.longitude, b.latitude, b.longitude);
    // ~26 km/h effective city speed, matching the pricing estimate's assumption.
    final mins = (km / 26.0 * 60).round().clamp(1, 1 << 30);
    return EvcRoute(
        points: [a, b], distanceKm: km, durationMin: mins, isReal: false);
  }
}

/// A point [t] (0..1) of the way along [pts], by cumulative distance. Used to
/// place a vehicle marker along a route.
LatLng pointAlong(List<LatLng> pts, double t) {
  if (pts.isEmpty) return kDubaiCenter;
  if (pts.length == 1 || t <= 0) return pts.first;
  if (t >= 1) return pts.last;

  final segLen = <double>[];
  var total = 0.0;
  for (var i = 0; i < pts.length - 1; i++) {
    final d = _haversineKm(pts[i].latitude, pts[i].longitude,
        pts[i + 1].latitude, pts[i + 1].longitude);
    segLen.add(d);
    total += d;
  }
  if (total == 0) return pts.first;

  var target = t * total;
  for (var i = 0; i < segLen.length; i++) {
    if (target <= segLen[i] || i == segLen.length - 1) {
      final f = segLen[i] == 0 ? 0.0 : (target / segLen[i]).clamp(0.0, 1.0);
      return LatLng(
        pts[i].latitude + (pts[i + 1].latitude - pts[i].latitude) * f,
        pts[i].longitude + (pts[i + 1].longitude - pts[i].longitude) * f,
      );
    }
    target -= segLen[i];
  }
  return pts.last;
}

/// Decode a Google encoded polyline string into coordinates.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          (math.sin(dLng / 2) * math.sin(dLng / 2));
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * (math.pi / 180.0);
