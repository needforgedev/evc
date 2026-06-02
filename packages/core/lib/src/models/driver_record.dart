import 'package:flutter/widgets.dart';

/// Account state of a driver as managed by Admin.
enum DriverAccountStatus { pending, active, suspended }

/// A driver as seen in the Admin drivers list / approval queue.
@immutable
class DriverRecord {
  const DriverRecord({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.rating,
    required this.totalTrips,
    required this.vehicleModel,
    required this.plate,
    required this.status,
    this.ownerLabel = 'Driver-owned',
    this.appliedLabel = '',
  });

  final String name;
  final String initials;
  final Color avatarColor;
  final double rating;
  final int totalTrips;
  final String vehicleModel;
  final String plate;
  final DriverAccountStatus status;
  final String ownerLabel;

  /// For pending applicants, e.g. "Applied 2 days ago".
  final String appliedLabel;

  DriverRecord copyWith({DriverAccountStatus? status}) => DriverRecord(
        name: name,
        initials: initials,
        avatarColor: avatarColor,
        rating: rating,
        totalTrips: totalTrips,
        vehicleModel: vehicleModel,
        plate: plate,
        status: status ?? this.status,
        ownerLabel: ownerLabel,
        appliedLabel: appliedLabel,
      );
}