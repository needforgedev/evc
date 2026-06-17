import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_maps/evc_maps.dart';

/// The 4 coordinates that key a route lookup (origin → destination).
typedef RouteKey = ({double oLat, double oLng, double dLat, double dLng});

/// Real road route (polyline + distance + drive-time) from the Directions API,
/// cached per origin/destination. Falls back to a straight line when the
/// Directions API is unavailable (see [EvcDirections]).
final routeProvider = FutureProvider.family<EvcRoute, RouteKey>((ref, k) {
  return EvcDirections.route(
    LatLng(k.oLat, k.oLng),
    LatLng(k.dLat, k.dLng),
  );
});
