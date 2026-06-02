import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';

/// All hardcoded data for the Driver mock. Swap for Supabase-backed
/// repositories later — screens talk to `evc_core` models, so they won't change.
abstract final class DriverMock {
  /// The signed-in driver's own position (pickup-area home base).
  static const Place driverLocation = Place(
    name: 'You',
    address: 'Business Bay',
    mapX: 0.40,
    mapY: 0.52,
  );

  /// The incoming ride request offered when the driver goes online.
  static const RideRequest offer = RideRequest(
    rider: RiderInfo(
      name: 'Aisha Khan',
      initials: 'AK',
      rating: 4.9,
      avatarColor: Color(0xFF7C3AED),
    ),
    pickup: Place(
      name: 'Emirates Towers',
      address: 'DIFC, Sheikh Zayed Rd',
      mapX: 0.62,
      mapY: 0.40,
    ),
    destination: Place(
      name: 'Marina Gate 1',
      address: 'Dubai Marina',
      mapX: 0.26,
      mapY: 0.64,
    ),
    tierName: 'EVC Comfort',
    fareAed: 33.00,
    distanceKm: 14.2,
    pickupMinutes: 4,
    tripMinutes: 18,
  );

  static const List<ChargingStation> stations = [
    ChargingStation(
      name: 'DEWA — Business Bay',
      network: 'DEWA EV Green Charger',
      distanceKm: 0.8,
      availableStalls: 3,
      totalStalls: 4,
      powerKw: 120,
      mapX: 0.46,
      mapY: 0.46,
    ),
    ChargingStation(
      name: 'DEWA — Downtown / Dubai Mall',
      network: 'DEWA EV Green Charger',
      distanceKm: 2.1,
      availableStalls: 0,
      totalStalls: 6,
      powerKw: 150,
      mapX: 0.62,
      mapY: 0.34,
    ),
    ChargingStation(
      name: 'DEWA — Sheikh Zayed Rd',
      network: 'DEWA EV Green Charger',
      distanceKm: 3.4,
      availableStalls: 2,
      totalStalls: 4,
      powerKw: 60,
      mapX: 0.30,
      mapY: 0.40,
    ),
    ChargingStation(
      name: 'DEWA — Marina',
      network: 'DEWA EV Green Charger',
      distanceKm: 5.0,
      availableStalls: 5,
      totalStalls: 8,
      powerKw: 120,
      mapX: 0.22,
      mapY: 0.62,
    ),
  ];

  static const EarningsSummary today = EarningsSummary(
    label: 'Today',
    totalAed: 286.50,
    trips: 9,
    onlineHours: 6.5,
    tipsAed: 24.0,
    entries: [
      EarningEntry(
        timeLabel: '13:20',
        routeLabel: 'DIFC → Dubai Marina',
        amountAed: 33.0,
        tipAed: 5.0,
      ),
      EarningEntry(
        timeLabel: '12:05',
        routeLabel: 'Downtown → Business Bay',
        amountAed: 21.5,
        tipAed: 0.0,
      ),
      EarningEntry(
        timeLabel: '10:48',
        routeLabel: 'JBR → Mall of the Emirates',
        amountAed: 38.0,
        tipAed: 10.0,
      ),
      EarningEntry(
        timeLabel: '09:31',
        routeLabel: 'Palm Jumeirah → DIFC',
        amountAed: 52.0,
        tipAed: 9.0,
      ),
    ],
  );

  static const EarningsSummary week = EarningsSummary(
    label: 'This week',
    totalAed: 1742.00,
    trips: 58,
    onlineHours: 38.5,
    tipsAed: 142.0,
    entries: [],
  );

  static const EarningsSummary month = EarningsSummary(
    label: 'This month',
    totalAed: 6985.50,
    trips: 241,
    onlineHours: 162.0,
    tipsAed: 540.0,
    entries: [],
  );
}