/// Lifecycle of a rider's trip. Drives what the live-tracking screen shows.
enum TripStage {
  idle,
  searching,
  enRouteToPickup,
  arrived,
  inProgress,
  completed;

  /// Whether a driver has been matched (card should be visible).
  bool get hasDriver =>
      this == enRouteToPickup || this == arrived || this == inProgress;

  /// Short status headline for the tracking screen.
  String get headline => switch (this) {
        idle => '',
        searching => 'Finding your EV…',
        enRouteToPickup => 'Your driver is on the way',
        arrived => 'Your driver has arrived',
        inProgress => 'On the way to your destination',
        completed => "You've arrived",
      };
}

/// A completed trip shown in ride history.
class TripHistoryEntry {
  const TripHistoryEntry({
    required this.dateLabel,
    required this.fromName,
    required this.toName,
    required this.tierName,
    required this.fareAed,
    required this.co2SavedKg,
  });

  final String dateLabel;
  final String fromName;
  final String toName;
  final String tierName;
  final double fareAed;
  final double co2SavedKg;
}