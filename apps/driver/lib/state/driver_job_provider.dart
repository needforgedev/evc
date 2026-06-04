import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// The driver's current active job (matched → ongoing), streamed in realtime.
final driverJobProvider = StreamProvider<ActiveTrip?>((ref) {
  final uid = EvcSupabase.currentUserId;
  if (!EvcSupabase.isReady || uid == null) return Stream.value(null);
  return EvcTrips.driverJobStream(uid);
});

/// A rider's profile summary (name / rating) for the request + trip cards.
final riderProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, riderId) => EvcTrips.profile(riderId));
