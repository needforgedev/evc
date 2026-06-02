import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';

/// Admin-local config types (pricing/promos) — not yet shared in core.
class ZoneSurge {
  const ZoneSurge(this.zone, this.multiplier);
  final String zone;
  final double multiplier;
}

class PromoCode {
  const PromoCode(this.code, this.description, this.redemptions, this.active);
  final String code;
  final String description;
  final int redemptions;
  final bool active;
}

class DemandBar {
  const DemandBar(this.hour, this.value);
  final String hour;
  final double value; // 0..1
}

/// A demand hotspot drawn on the live ops map.
class Hotspot {
  const Hotspot(this.mapX, this.mapY, this.intensity);
  final double mapX;
  final double mapY;
  final double intensity; // 0..1
}

/// All hardcoded data for the Admin mock.
abstract final class AdminMock {
  // ---- Fleet / live drivers (also plotted on the ops map) ----
  static const List<FleetVehicle> fleet = [
    FleetVehicle(
      plate: 'K 48213',
      model: 'Tesla Model 3',
      ownership: OwnershipType.driver,
      batteryPercent: 78,
      rangeKm: 312,
      status: VehicleStatus.active,
      driverName: 'Omar Al Farsi',
      mapX: 0.40,
      mapY: 0.52,
    ),
    FleetVehicle(
      plate: 'B 11920',
      model: 'BYD Atto 3',
      ownership: OwnershipType.company,
      batteryPercent: 24,
      rangeKm: 96,
      status: VehicleStatus.charging,
      driverName: 'Yusuf Khan',
      mapX: 0.62,
      mapY: 0.34,
    ),
    FleetVehicle(
      plate: 'D 77410',
      model: 'Tesla Model Y',
      ownership: OwnershipType.company,
      batteryPercent: 91,
      rangeKm: 402,
      status: VehicleStatus.active,
      driverName: 'Sara Ahmed',
      mapX: 0.26,
      mapY: 0.62,
    ),
    FleetVehicle(
      plate: 'A 30188',
      model: 'Hyundai Ioniq 5',
      ownership: OwnershipType.driver,
      batteryPercent: 0,
      rangeKm: 0,
      status: VehicleStatus.maintenance,
      driverName: 'Bilal Noor',
      mapX: 0.78,
      mapY: 0.58,
    ),
    FleetVehicle(
      plate: 'C 55027',
      model: 'Tesla Model 3',
      ownership: OwnershipType.company,
      batteryPercent: 64,
      rangeKm: 268,
      status: VehicleStatus.active,
      driverName: 'Mariam Saleh',
      mapX: 0.54,
      mapY: 0.66,
    ),
  ];

  static const List<Hotspot> hotspots = [
    Hotspot(0.62, 0.36, 0.9),
    Hotspot(0.28, 0.62, 0.7),
    Hotspot(0.48, 0.5, 0.5),
  ];

  // ---- Trips ----
  static const List<AdminTrip> trips = [
    AdminTrip(
      id: 'T-90412',
      riderName: 'Aisha Khan',
      driverName: 'Omar Al Farsi',
      fromName: 'Emirates Towers, DIFC',
      toName: 'Marina Gate 1',
      tierName: 'EVC Comfort',
      fareAed: 33.0,
      status: AdminTripStatus.ongoing,
      stageLabel: 'En route to pickup',
      etaMinutes: 4,
      mapX: 0.55,
      mapY: 0.45,
    ),
    AdminTrip(
      id: 'T-90411',
      riderName: 'Hassan Ali',
      driverName: 'Sara Ahmed',
      fromName: 'The Dubai Mall',
      toName: 'Business Bay',
      tierName: 'EVC Go',
      fareAed: 21.5,
      status: AdminTripStatus.ongoing,
      stageLabel: 'Trip in progress',
      etaMinutes: 9,
      mapX: 0.36,
      mapY: 0.58,
    ),
    AdminTrip(
      id: 'T-90408',
      riderName: 'Layla Hassan',
      driverName: 'Mariam Saleh',
      fromName: 'JBR — The Beach',
      toName: 'Mall of the Emirates',
      tierName: 'EVC XL',
      fareAed: 47.0,
      status: AdminTripStatus.ongoing,
      stageLabel: 'Trip in progress',
      etaMinutes: 14,
      mapX: 0.5,
      mapY: 0.64,
    ),
    AdminTrip(
      id: 'T-90399',
      riderName: 'Noura Saeed',
      driverName: 'Yusuf Khan',
      fromName: 'Palm Jumeirah',
      toName: 'DIFC',
      tierName: 'EVC Green Premium',
      fareAed: 62.0,
      status: AdminTripStatus.completed,
      stageLabel: 'Completed',
      etaMinutes: 0,
      mapX: 0.3,
      mapY: 0.4,
    ),
    AdminTrip(
      id: 'T-90388',
      riderName: 'Omar Idris',
      driverName: 'Omar Al Farsi',
      fromName: 'DXB Terminal 3',
      toName: 'Downtown Dubai',
      tierName: 'EVC Comfort',
      fareAed: 38.0,
      status: AdminTripStatus.completed,
      stageLabel: 'Completed',
      etaMinutes: 0,
      mapX: 0.7,
      mapY: 0.3,
    ),
  ];

  // ---- Drivers (approval queue + roster) ----
  static const List<DriverRecord> drivers = [
    DriverRecord(
      name: 'Khalid Mansour',
      initials: 'KM',
      avatarColor: Color(0xFFEA580C),
      rating: 0,
      totalTrips: 0,
      vehicleModel: 'BYD Dolphin',
      plate: 'pending',
      status: DriverAccountStatus.pending,
      ownerLabel: 'Driver-owned',
      appliedLabel: 'Applied 2 days ago',
    ),
    DriverRecord(
      name: 'Fatima Noor',
      initials: 'FN',
      avatarColor: Color(0xFF0891B2),
      rating: 0,
      totalTrips: 0,
      vehicleModel: 'Tesla Model 3 (company)',
      plate: 'pending',
      status: DriverAccountStatus.pending,
      ownerLabel: 'Company-owned',
      appliedLabel: 'Applied 5 hours ago',
    ),
    DriverRecord(
      name: 'Omar Al Farsi',
      initials: 'OA',
      avatarColor: Color(0xFF2563EB),
      rating: 4.93,
      totalTrips: 2841,
      vehicleModel: 'Tesla Model 3',
      plate: 'K 48213',
      status: DriverAccountStatus.active,
    ),
    DriverRecord(
      name: 'Sara Ahmed',
      initials: 'SA',
      avatarColor: Color(0xFF7C3AED),
      rating: 4.88,
      totalTrips: 1530,
      vehicleModel: 'Tesla Model Y',
      plate: 'D 77410',
      status: DriverAccountStatus.active,
      ownerLabel: 'Company-owned',
    ),
    DriverRecord(
      name: 'Bilal Noor',
      initials: 'BN',
      avatarColor: Color(0xFF65A30D),
      rating: 4.41,
      totalTrips: 612,
      vehicleModel: 'Hyundai Ioniq 5',
      plate: 'A 30188',
      status: DriverAccountStatus.suspended,
    ),
  ];

  // ---- Support tickets ----
  static const List<SupportTicket> tickets = [
    SupportTicket(
      id: 'S-2231',
      subject: 'Lost phone in vehicle K 48213',
      type: TicketType.lostItem,
      fromName: 'Aisha Khan (rider)',
      status: TicketStatus.open,
      timeLabel: '12 min ago',
    ),
    SupportTicket(
      id: 'S-2229',
      subject: 'Driver took a longer route',
      type: TicketType.fare,
      fromName: 'Hassan Ali (rider)',
      status: TicketStatus.pending,
      timeLabel: '1 hour ago',
    ),
    SupportTicket(
      id: 'S-2218',
      subject: 'Safety — harsh braking reported',
      type: TicketType.safety,
      fromName: 'Layla Hassan (rider)',
      status: TicketStatus.open,
      timeLabel: '3 hours ago',
    ),
    SupportTicket(
      id: 'S-2204',
      subject: 'Payout not received',
      type: TicketType.general,
      fromName: 'Yusuf Khan (driver)',
      status: TicketStatus.resolved,
      timeLabel: 'Yesterday',
    ),
  ];

  // ---- Pricing & promos ----
  static const double baseFare = 8.0;
  static const double perKm = 1.9;
  static const double perMin = 0.45;
  static const List<ZoneSurge> surges = [
    ZoneSurge('Downtown / DIFC', 1.4),
    ZoneSurge('Dubai Marina / JBR', 1.2),
    ZoneSurge('DXB Airport', 1.6),
    ZoneSurge('Deira / Bur Dubai', 1.0),
  ];
  static const List<PromoCode> promos = [
    PromoCode('GREEN20', '20% off, max AED 15', 1840, true),
    PromoCode('WELCOME', 'AED 25 off first ride', 6120, true),
    PromoCode('EID10', '10% off all rides', 940, false),
  ];

  // ---- Demand by hour (analytics) ----
  static const List<DemandBar> demand = [
    DemandBar('6a', 0.2),
    DemandBar('8a', 0.7),
    DemandBar('10a', 0.5),
    DemandBar('12p', 0.6),
    DemandBar('2p', 0.45),
    DemandBar('4p', 0.55),
    DemandBar('6p', 0.85),
    DemandBar('8p', 1.0),
    DemandBar('10p', 0.65),
  ];
}