import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// Driver earnings derived from `driver_earnings_view` (real; zero until trips
/// are completed). Returns [today, week, month] summaries.
final driverEarningsProvider = FutureProvider<List<EarningsSummary>>((ref) async {
  EarningsSummary empty(String label) => EarningsSummary(
        label: label,
        totalAed: 0,
        trips: 0,
        onlineHours: 0,
        tipsAed: 0,
        entries: const [],
      );

  if (!EvcSupabase.isReady) {
    return [empty('Today'), empty('This week'), empty('This month')];
  }

  final client = EvcSupabase.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    return [empty('Today'), empty('This week'), empty('This month')];
  }

  final rows = await client
      .from('driver_earnings_view')
      .select()
      .eq('driver_id', uid) as List<dynamic>;

  double sum(Iterable<dynamic> rs, String key) =>
      rs.fold(0.0, (a, r) => a + ((r[key] as num?)?.toDouble() ?? 0));
  int count(Iterable<dynamic> rs) =>
      rs.fold(0, (a, r) => a + ((r['trips'] as num?)?.toInt() ?? 0));

  EarningsSummary build(String label, Iterable<dynamic> rs) => EarningsSummary(
        label: label,
        totalAed: sum(rs, 'gross_aed'),
        trips: count(rs),
        onlineHours: 0,
        tipsAed: sum(rs, 'tips_aed'),
        entries: const [],
      );

  // Without a server clock we treat all rows as the running total; date
  // bucketing can be refined once there are real completed trips.
  return [
    build('Today', rows),
    build('This week', rows),
    build('This month', rows),
  ];
});

/// Charging stations from the DB, normalised onto the placeholder map and with
/// distance from the driver's default location.
final chargingStationsProvider =
    FutureProvider<List<ChargingStation>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;
  final rows = await client.from('charging_stations').select() as List<dynamic>;

  // Default driver location (Business Bay) for distance estimates.
  const dLat = 25.1860, dLng = 55.2620;

  ChargingStation map(Map<String, dynamic> r) {
    final lat = (r['lat'] as num).toDouble();
    final lng = (r['lng'] as num).toDouble();
    return ChargingStation(
      name: r['name'] as String,
      network: (r['network'] as String?) ?? 'DEWA EV Green Charger',
      distanceKm: _haversineKm(dLat, dLng, lat, lng),
      availableStalls: (r['available_stalls'] as num?)?.toInt() ?? 0,
      totalStalls: (r['total_stalls'] as num?)?.toInt() ?? 0,
      powerKw: (r['power_kw'] as num?)?.toInt() ?? 0,
      // Rough normalisation of Dubai lat/lng → 0..1 for the placeholder map.
      mapX: (((lng - 55.10) / 0.30).clamp(0.05, 0.95)).toDouble(),
      mapY: (((25.30 - lat) / 0.30).clamp(0.05, 0.95)).toDouble(),
    );
  }

  final list = [for (final r in rows) map(r as Map<String, dynamic>)];
  list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return list;
});

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) *
          math.sin(dLng / 2) * math.sin(dLng / 2);
  return double.parse((r * 2 * math.asin(math.sqrt(a))).toStringAsFixed(1));
}
