import 'place.dart';
import 'rider_info.dart';

/// An incoming trip offer presented to a driver (accept/decline).
class RideRequest {
  const RideRequest({
    required this.rider,
    required this.pickup,
    required this.destination,
    required this.tierName,
    required this.fareAed,
    required this.distanceKm,
    required this.pickupMinutes,
    required this.tripMinutes,
  });

  final RiderInfo rider;
  final Place pickup;
  final Place destination;
  final String tierName;

  /// What the driver earns (gross fare) in AED.
  final double fareAed;

  /// Trip distance once picked up.
  final double distanceKm;

  /// Minutes to reach the pickup.
  final int pickupMinutes;

  /// Minutes from pickup to destination.
  final int tripMinutes;
}

/// Lifecycle of the job a driver is fulfilling.
enum JobStage {
  none,
  offered,
  enRouteToPickup,
  arrived,
  inProgress,
  completed;

  String get headline => switch (this) {
        none => '',
        offered => 'New ride request',
        enRouteToPickup => 'Head to pickup',
        arrived => 'Waiting for rider',
        inProgress => 'Trip in progress',
        completed => 'Trip complete',
      };
}