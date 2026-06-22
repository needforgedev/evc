import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// The assigned driver's live position (Realtime), keyed by driver id. Drives
/// the moving car marker on the live-trip map.
final driverLocationProvider =
    StreamProvider.family<LivePosition?, String>((ref, driverId) {
  return EvcTrips.driverLocationStream(driverId);
});
