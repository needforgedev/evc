import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// Realtime stream of a single live trip (status updates as it progresses).
final tripStreamProvider =
    StreamProvider.family<ActiveTrip?, String>((ref, id) {
  return EvcTrips.tripStream(id);
});
