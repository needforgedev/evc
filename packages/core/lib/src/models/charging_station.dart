import 'package:flutter/widgets.dart';

/// A charging location shown on the Driver charging map (DEWA EV Green Charger
/// network in Dubai). [mapX]/[mapY] are 0..1 placeholder-map coordinates.
@immutable
class ChargingStation {
  const ChargingStation({
    required this.name,
    required this.network,
    required this.distanceKm,
    required this.availableStalls,
    required this.totalStalls,
    required this.powerKw,
    required this.mapX,
    required this.mapY,
  });

  final String name;
  final String network;
  final double distanceKm;
  final int availableStalls;
  final int totalStalls;
  final int powerKw;
  final double mapX;
  final double mapY;

  bool get hasAvailability => availableStalls > 0;
}