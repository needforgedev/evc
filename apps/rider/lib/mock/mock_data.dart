import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';

/// All hardcoded data for the Rider mock. Replace with Supabase-backed
/// repositories as Phase 1 is built out — the rest of the app talks to these
/// values through models in `evc_core`, so screens won't change.
abstract final class MockData {
  /// The rider's current GPS location (pickup default).
  static const Place currentLocation = Place(
    name: 'Current location',
    address: 'Dubai Marina, Marina Walk',
    kind: PlaceKind.pin,
    lat: 25.0805,
    lng: 55.1403,
    mapX: 0.28,
    mapY: 0.62,
  );

  static const Place home = Place(
    name: 'Home',
    address: 'Marina Gate 1, Dubai Marina',
    kind: PlaceKind.home,
    lat: 25.0760,
    lng: 55.1380,
    mapX: 0.30,
    mapY: 0.66,
  );

  static const Place work = Place(
    name: 'Work',
    address: 'Emirates Towers, DIFC',
    kind: PlaceKind.work,
    lat: 25.2170,
    lng: 55.2820,
    mapX: 0.66,
    mapY: 0.40,
  );

  /// Saved shortcuts shown on the home sheet.
  static const List<Place> savedPlaces = [home, work];

  /// Recent + searchable destinations.
  static const List<Place> places = [
    Place(
      name: 'The Dubai Mall',
      address: 'Financial Center Rd, Downtown Dubai',
      kind: PlaceKind.recent,
      lat: 25.1972,
      lng: 55.2796,
      mapX: 0.62,
      mapY: 0.34,
    ),
    Place(
      name: 'Burj Khalifa',
      address: '1 Sheikh Mohammed bin Rashid Blvd',
      kind: PlaceKind.recent,
      lat: 25.1972,
      lng: 55.2744,
      mapX: 0.60,
      mapY: 0.30,
    ),
    Place(
      name: 'DXB — Dubai International Airport',
      address: 'Terminal 3, Garhoud',
      kind: PlaceKind.search,
      lat: 25.2528,
      lng: 55.3644,
      mapX: 0.82,
      mapY: 0.22,
    ),
    Place(
      name: 'Palm Jumeirah',
      address: 'Atlantis The Palm, Crescent Rd',
      kind: PlaceKind.search,
      lat: 25.1304,
      lng: 55.1171,
      mapX: 0.18,
      mapY: 0.48,
    ),
    Place(
      name: 'JBR — The Beach',
      address: 'Jumeirah Beach Residence',
      kind: PlaceKind.search,
      lat: 25.0785,
      lng: 55.1340,
      mapX: 0.22,
      mapY: 0.58,
    ),
    Place(
      name: 'Mall of the Emirates',
      address: 'Sheikh Zayed Rd, Al Barsha',
      kind: PlaceKind.search,
      lat: 25.1181,
      lng: 55.2003,
      mapX: 0.46,
      mapY: 0.44,
    ),
    Place(
      name: 'Business Bay',
      address: 'Marasi Dr, Business Bay',
      kind: PlaceKind.search,
      lat: 25.1850,
      lng: 55.2620,
      mapX: 0.58,
      mapY: 0.40,
    ),
  ];

  /// Ride classes for the booking screen. Fares are illustrative AED.
  static const List<RideTier> tiers = [
    RideTier(
      id: 'go',
      name: 'EVC Go',
      blurb: 'Compact EV · 3 seats',
      seats: 3,
      fareAed: 24.50,
      etaMinutes: 3,
      co2SavedKg: 2.1,
      icon: Icons.directions_car_filled,
    ),
    RideTier(
      id: 'comfort',
      name: 'EVC Comfort',
      blurb: 'Newer EVs, extra legroom · 4 seats',
      seats: 4,
      fareAed: 33.00,
      etaMinutes: 4,
      co2SavedKg: 2.4,
      icon: Icons.airline_seat_recline_extra,
    ),
    RideTier(
      id: 'xl',
      name: 'EVC XL',
      blurb: 'SUV / van · 6 seats',
      seats: 6,
      fareAed: 47.00,
      etaMinutes: 6,
      co2SavedKg: 3.2,
      icon: Icons.airport_shuttle,
    ),
    RideTier(
      id: 'premium',
      name: 'EVC Green Premium',
      blurb: 'Tesla / luxury EV · 3 seats',
      seats: 3,
      fareAed: 62.00,
      etaMinutes: 5,
      co2SavedKg: 2.8,
      icon: Icons.electric_car,
    ),
  ];

  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      type: PaymentType.card,
      label: 'Visa',
      detail: '•••• 4242',
      icon: Icons.credit_card,
    ),
    PaymentMethod(
      type: PaymentType.cash,
      label: 'Cash',
      detail: 'Pay the driver directly',
      icon: Icons.payments_outlined,
    ),
    PaymentMethod(
      type: PaymentType.applePay,
      label: 'Apple Pay',
      detail: 'iPhone',
      icon: Icons.apple,
    ),
    PaymentMethod(
      type: PaymentType.wallet,
      label: 'EVC Wallet',
      detail: 'AED 120.00',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  /// The driver a rider gets matched to in the mock.
  static const DriverProfile driver = DriverProfile(
    name: 'Omar Al Farsi',
    initials: 'OA',
    rating: 4.93,
    totalTrips: 2841,
    vehicleModel: 'Tesla Model 3',
    vehicleColor: 'Pearl White',
    plate: 'Dubai · K 48213',
    avatarColor: Color(0xFF2563EB),
    batteryPercent: 78,
  );

  static const List<TripHistoryEntry> history = [
    TripHistoryEntry(
      dateLabel: 'Today · 09:14',
      fromName: 'Home',
      toName: 'Emirates Towers, DIFC',
      tierName: 'EVC Comfort',
      fareAed: 33.00,
      co2SavedKg: 2.4,
    ),
    TripHistoryEntry(
      dateLabel: 'Yesterday · 20:41',
      fromName: 'The Dubai Mall',
      toName: 'Marina Gate 1',
      tierName: 'EVC Go',
      fareAed: 26.50,
      co2SavedKg: 2.2,
    ),
    TripHistoryEntry(
      dateLabel: 'Sat, 31 May · 16:08',
      fromName: 'DXB Terminal 3',
      toName: 'Palm Jumeirah',
      tierName: 'EVC XL',
      fareAed: 58.00,
      co2SavedKg: 3.5,
    ),
  ];
}