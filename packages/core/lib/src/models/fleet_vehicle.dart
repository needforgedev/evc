import 'package:flutter/widgets.dart';

/// Whether an EV is company-owned or owned by the driver (hybrid fleet model).
enum OwnershipType { company, driver }

enum VehicleStatus { active, charging, maintenance, offline }

/// A vehicle in the fleet registry (Admin). [mapX]/[mapY] place it on the live
/// ops map.
@immutable
class FleetVehicle {
  const FleetVehicle({
    required this.plate,
    required this.model,
    required this.ownership,
    required this.batteryPercent,
    required this.rangeKm,
    required this.status,
    required this.driverName,
    required this.mapX,
    required this.mapY,
  });

  final String plate;
  final String model;
  final OwnershipType ownership;
  final int batteryPercent;
  final int rangeKm;
  final VehicleStatus status;
  final String driverName;
  final double mapX;
  final double mapY;
}