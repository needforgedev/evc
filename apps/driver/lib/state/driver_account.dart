import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// The signed-in driver, assembled from profiles + driver_details + vehicle.
@immutable
class DriverAccount {
  const DriverAccount({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.rating,
    required this.totalTrips,
    required this.status,
    required this.acceptanceRate,
    required this.isOnline,
    this.vehicleId,
    required this.vehicleModel,
    required this.plate,
    required this.ownerLabel,
    required this.batteryPercent,
    required this.rangeKm,
    required this.vehicleStatus,
  });

  final String id;
  final String fullName;
  final String phone;
  final double rating;
  final int totalTrips;
  final DriverAccountStatus status;
  final double acceptanceRate;
  final bool isOnline;

  final String? vehicleId;
  final String vehicleModel;
  final String plate;
  final String ownerLabel;
  final int batteryPercent;
  final int rangeKm;
  final VehicleStatus vehicleStatus;

  bool get isActive => status == DriverAccountStatus.active;
  bool get hasVehicle => plate.isNotEmpty;
  bool get isCharging => vehicleStatus == VehicleStatus.charging;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'EV';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static int _i(dynamic v, [int d = 0]) => (v as num?)?.toInt() ?? d;
  static double _d(dynamic v, [double d = 0]) => (v as num?)?.toDouble() ?? d;

  factory DriverAccount.fromRows(
    Map<String, dynamic> profile,
    Map<String, dynamic>? details,
    Map<String, dynamic>? vehicle,
  ) {
    return DriverAccount(
      id: profile['id'] as String,
      fullName: (profile['full_name'] as String?) ?? 'Driver',
      phone: (profile['phone'] as String?) ?? '',
      rating: _d(profile['rating'], 5),
      totalTrips: _i(profile['total_trips']),
      status: DriverAccountStatus.values
          .byName((details?['account_status'] as String?) ?? 'pending'),
      acceptanceRate: _d(details?['acceptance_rate'], 100),
      isOnline: (details?['is_online'] as bool?) ?? false,
      vehicleId: details?['current_vehicle_id'] as String?,
      vehicleModel: (vehicle?['model'] as String?) ?? '',
      plate: (vehicle?['plate'] as String?) ?? '',
      ownerLabel: (details?['owner_label'] as String?) ?? 'Driver-owned',
      batteryPercent: _i(vehicle?['battery_percent']),
      rangeKm: _i(vehicle?['range_km']),
      vehicleStatus: VehicleStatus.values
          .byName((vehicle?['status'] as String?) ?? 'offline'),
    );
  }
}

/// Loads the current driver from Supabase. Null when not signed in / not
/// configured (the app then stays in pure-mock mode).
final currentDriverProvider = FutureProvider<DriverAccount?>((ref) async {
  if (!EvcSupabase.isReady) return null;
  final client = EvcSupabase.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;

  final profile =
      await client.from('profiles').select().eq('id', uid).single();
  final details = await client
      .from('driver_details')
      .select()
      .eq('driver_id', uid)
      .maybeSingle();

  Map<String, dynamic>? vehicle;
  final vehicleId = details?['current_vehicle_id'];
  if (vehicleId != null) {
    vehicle = await client
        .from('vehicles')
        .select()
        .eq('id', vehicleId)
        .maybeSingle();
  }
  return DriverAccount.fromRows(profile, details, vehicle);
});

/// Live driver mutations against Supabase.
abstract final class DriverActions {
  // Default GPS until real geolocation is added (Business Bay, Dubai).
  static const double _lat = 25.1860;
  static const double _lng = 55.2620;

  static Future<void> goOnline(bool online) async {
    if (!EvcSupabase.isReady) return;
    final client = EvcSupabase.client;
    await client.rpc('driver_set_online', params: {'p_online': online});
    if (online) {
      await client.rpc('driver_update_location',
          params: {'p_lat': _lat, 'p_lng': _lng});
    }
  }

  static Future<void> setCharging(bool charging, String? vehicleId) async {
    if (!EvcSupabase.isReady || vehicleId == null) return;
    final client = EvcSupabase.client;
    await client
        .from('vehicles')
        .update({'status': charging ? 'charging' : 'active'}).eq('id', vehicleId);
    if (charging) {
      await client.rpc('driver_set_online', params: {'p_online': false});
    }
  }

  static Future<void> signOut() async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.auth.signOut();
  }
}
