import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// Pickup + trip-distance key for an availability lookup.
typedef AvailabilityKey = ({double lat, double lng, double dist});

/// Per-tier availability near the pickup, keyed by `tierId`. Empty map while it
/// loads or if the lookup fails (the UI then shows generic estimates).
final tierAvailabilityProvider =
    FutureProvider.family<Map<String, TierAvailability>, AvailabilityKey>(
        (ref, k) async {
  final list = await EvcTrips.nearbyTiers(
    pickupLat: k.lat,
    pickupLng: k.lng,
    distanceKm: k.dist,
  );
  return {for (final t in list) t.tierId: t};
});
