import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// The assigned driver + their vehicle, as the rider is allowed to see them.
/// RLS: the rider can read the driver's `profiles` row only while they share a
/// trip; `vehicles` is world-readable; `driver_details` is NOT rider-readable,
/// so the vehicle is fetched by the trip's `vehicleId` (carried on the trip row).
class AssignedDriver {
  const AssignedDriver({
    required this.name,
    required this.phone,
    required this.rating,
    required this.totalTrips,
    required this.vehicleModel,
    required this.plate,
    required this.batteryPercent,
    required this.rangeKm,
  });

  final String name;
  final String? phone;
  final double rating;
  final int totalTrips;
  final String vehicleModel;
  final String plate;
  final int batteryPercent;
  final int rangeKm;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

final assignedDriverProvider =
    FutureProvider.family<AssignedDriver?, (String, String?)>(
        (ref, key) async {
  final (driverId, vehicleId) = key;
  final client = EvcSupabase.client;

  final profile = await client
      .from('profiles')
      .select('full_name, phone, rating, total_trips')
      .eq('id', driverId)
      .maybeSingle();
  if (profile == null) return null;

  Map<String, dynamic>? v;
  if (vehicleId != null) {
    v = await client
        .from('vehicles')
        .select('model, plate, battery_percent, range_km')
        .eq('id', vehicleId)
        .maybeSingle();
  }

  final name = (profile['full_name'] as String?)?.trim();
  return AssignedDriver(
    name: (name != null && name.isNotEmpty) ? name : 'Your driver',
    phone: (profile['phone'] as String?)?.trim(),
    rating: _d(profile['rating']) == 0 ? 5 : _d(profile['rating']),
    totalTrips: (profile['total_trips'] as int?) ?? 0,
    vehicleModel: (v?['model'] as String?) ?? 'Electric vehicle',
    plate: (v?['plate'] as String?) ?? '—',
    batteryPercent: (v?['battery_percent'] as int?) ?? 0,
    rangeKm: (v?['range_km'] as int?) ?? 0,
  );
});

/// The settled payment for a completed trip (for the receipt).
class TripPayment {
  const TripPayment({
    required this.amount,
    required this.vat,
    required this.tip,
    required this.type,
    required this.status,
  });

  final double amount;
  final double vat;
  final double tip;
  final String type;
  final String status;

  double get total => amount + tip;
}

final tripPaymentProvider =
    FutureProvider.family<TripPayment?, String>((ref, tripId) async {
  final row = await EvcSupabase.client
      .from('payments')
      .select('amount, vat, tip, type, status')
      .eq('trip_id', tripId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
  if (row == null) return null;
  return TripPayment(
    amount: _d(row['amount']),
    vat: _d(row['vat']),
    tip: _d(row['tip']),
    type: (row['type'] as String?) ?? 'cash',
    status: (row['status'] as String?) ?? 'pending',
  );
});
