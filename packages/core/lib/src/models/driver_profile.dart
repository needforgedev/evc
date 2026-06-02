import 'package:flutter/widgets.dart';

/// The matched driver + their EV, shown on the live-tracking screen.
@immutable
class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.initials,
    required this.rating,
    required this.totalTrips,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.plate,
    required this.avatarColor,
    this.batteryPercent = 100,
  });

  final String name;

  /// Used to render a lightweight avatar (no network images in the mock).
  final String initials;
  final double rating;
  final int totalTrips;

  final String vehicleModel;
  final String vehicleColor;
  final String plate;

  /// Brand colour for the avatar circle.
  final Color avatarColor;

  /// Remaining battery — powers the "battery-aware assurance" indicator.
  final int batteryPercent;
}