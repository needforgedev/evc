import '../models/payment_method.dart';

/// Lifecycle status of a live trip (mirrors the DB `trip_status` enum).
enum LiveTripStatus {
  requested,
  matched,
  enroute,
  arrived,
  ongoing,
  completed,
  canceled;

  static LiveTripStatus parse(String? s) =>
      LiveTripStatus.values.asNameMap()[s] ?? LiveTripStatus.requested;

  bool get hasDriver =>
      this == matched || this == enroute || this == arrived || this == ongoing;
  bool get isActive => this != completed && this != canceled;
}

/// A live trip row (`public.trips`) as the apps see it.
class ActiveTrip {
  const ActiveTrip({
    required this.id,
    required this.status,
    this.riderId,
    this.driverId,
    this.vehicleId,
    required this.tierId,
    required this.pickupName,
    required this.destName,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
    this.fareEstimate,
    this.finalFare,
    this.vat,
    this.tip,
    this.co2SavedKg,
    this.distanceKm,
    this.durationMin,
    this.pin,
  });

  final String id;
  final LiveTripStatus status;
  final String? riderId;
  final String? driverId;
  final String? vehicleId;
  final String tierId;
  final String pickupName;
  final String destName;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;
  final double? fareEstimate;
  final double? finalFare;
  final double? vat;
  final double? tip;
  final double? co2SavedKg;
  final double? distanceKm;
  final int? durationMin;
  final String? pin;

  double get fare => finalFare ?? fareEstimate ?? 0;

  static double? _d(dynamic v) => (v as num?)?.toDouble();
  static int? _i(dynamic v) => (v as num?)?.toInt();

  factory ActiveTrip.fromRow(Map<String, dynamic> r) => ActiveTrip(
        id: r['id'] as String,
        status: LiveTripStatus.parse(r['status'] as String?),
        riderId: r['rider_id'] as String?,
        driverId: r['driver_id'] as String?,
        vehicleId: r['vehicle_id'] as String?,
        tierId: (r['tier_id'] as String?) ?? 'go',
        pickupName: (r['pickup_name'] ?? r['pickup_address'] ?? 'Pickup') as String,
        destName: (r['dest_name'] ?? r['dest_address'] ?? 'Destination') as String,
        pickupLat: _d(r['pickup_lat']),
        pickupLng: _d(r['pickup_lng']),
        destLat: _d(r['dest_lat']),
        destLng: _d(r['dest_lng']),
        fareEstimate: _d(r['fare_estimate']),
        finalFare: _d(r['final_fare']),
        vat: _d(r['vat']),
        tip: _d(r['tip']),
        co2SavedKg: _d(r['co2_saved_kg']),
        distanceKm: _d(r['distance_km']),
        durationMin: _i(r['duration_min']),
        pin: r['pin'] as String?,
      );
}

/// Maps the app payment enum to the DB `payment_type` enum value.
String paymentTypeToDb(PaymentType t) => switch (t) {
      PaymentType.applePay => 'apple_pay',
      PaymentType.cash => 'cash',
      PaymentType.card => 'card',
      PaymentType.wallet => 'wallet',
    };
