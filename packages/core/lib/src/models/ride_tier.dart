import 'package:flutter/widgets.dart';

/// A bookable ride class (EVC Go / Comfort / XL / Green Premium).
@immutable
class RideTier {
  const RideTier({
    required this.id,
    required this.name,
    required this.blurb,
    required this.seats,
    required this.fareAed,
    required this.etaMinutes,
    required this.co2SavedKg,
    required this.icon,
  });

  final String id;
  final String name;
  final String blurb;
  final int seats;

  /// Upfront fare in AED.
  final double fareAed;

  /// Minutes until pickup.
  final int etaMinutes;

  /// CO₂ saved vs. an equivalent petrol trip, in kilograms (brand hook).
  final double co2SavedKg;

  final IconData icon;
}