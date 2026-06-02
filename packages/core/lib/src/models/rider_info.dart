import 'package:flutter/widgets.dart';

/// The passenger, as seen by the Driver app on a ride request / active trip.
@immutable
class RiderInfo {
  const RiderInfo({
    required this.name,
    required this.initials,
    required this.rating,
    required this.avatarColor,
  });

  final String name;
  final String initials;
  final double rating;
  final Color avatarColor;
}