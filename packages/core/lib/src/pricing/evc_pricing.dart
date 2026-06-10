import 'dart:math' as math;

import '../supabase/evc_supabase.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Region pricing parameters (from the `pricing` table).
class PricingConfig {
  const PricingConfig({
    required this.baseFare,
    required this.perKm,
    required this.perMin,
    required this.minFare,
    required this.vatRate,
    required this.currency,
  });

  final double baseFare;
  final double perKm;
  final double perMin;
  final double minFare;
  final double vatRate;
  final String currency;

  /// Sensible fallback if the row can't be read (keeps the UI from showing 0).
  static const fallback = PricingConfig(
    baseFare: 8,
    perKm: 2.5,
    perMin: 0.5,
    minFare: 12,
    vatRate: 0.05,
    currency: 'AED',
  );

  factory PricingConfig.fromRow(Map<String, dynamic> r) => PricingConfig(
        baseFare: _d(r['base_fare']),
        perKm: _d(r['per_km']),
        perMin: _d(r['per_min']),
        minFare: _d(r['min_fare']),
        vatRate: _d(r['vat_rate']) == 0 ? 0.05 : _d(r['vat_rate']),
        currency: (r['currency'] as String?) ?? 'AED',
      );
}

/// A ride tier (from the `ride_tiers` table).
class RideTierConfig {
  const RideTierConfig({
    required this.id,
    required this.name,
    required this.blurb,
    required this.seats,
    required this.multiplier,
  });

  final String id;
  final String name;
  final String blurb;
  final int seats;
  final double multiplier;

  factory RideTierConfig.fromRow(Map<String, dynamic> r) => RideTierConfig(
        id: r['id'] as String,
        name: (r['name'] as String?) ?? (r['id'] as String),
        blurb: (r['blurb'] as String?) ?? '',
        seats: (r['seats'] as int?) ?? 4,
        multiplier: _d(r['multiplier']) == 0 ? 1 : _d(r['multiplier']),
      );
}

/// Computed estimate for one tier over a given distance.
class FareEstimate {
  const FareEstimate({
    required this.fare,
    required this.durationMin,
    required this.distanceKm,
    required this.co2Kg,
  });

  final double fare;
  final int durationMin;
  final double distanceKm;
  final double co2Kg;
}

/// Client-side fare estimation that **mirrors the server `request_ride` formula**
/// exactly, so the upfront quote equals the charged fare for the same coords.
abstract final class EvcPricing {
  static Future<PricingConfig> fetchPricing({String region = 'dubai'}) async {
    if (!EvcSupabase.isReady) return PricingConfig.fallback;
    final row = await EvcSupabase.client
        .from('pricing')
        .select()
        .eq('region', region)
        .maybeSingle();
    return row == null ? PricingConfig.fallback : PricingConfig.fromRow(row);
  }

  static Future<List<RideTierConfig>> fetchTiers() async {
    if (!EvcSupabase.isReady) return const [];
    final rows = await EvcSupabase.client
        .from('ride_tiers')
        .select()
        .eq('active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => RideTierConfig.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Mirrors `request_ride`: dur = ceil(dist/0.4) (~24 km/h), fare = max(min_fare,
  /// (base + per_km·dist + per_min·dur)·multiplier), CO₂ = dist·0.15.
  static FareEstimate estimate({
    required double distanceKm,
    required double multiplier,
    required PricingConfig p,
  }) {
    final dist = distanceKm <= 0 ? 0.0 : distanceKm;
    final dur = math.max(1, (dist / 0.4).ceil());
    final raw = (p.baseFare + p.perKm * dist + p.perMin * dur) * multiplier;
    final fare = math.max(p.minFare, raw);
    return FareEstimate(
      fare: fare,
      durationMin: dur,
      distanceKm: dist,
      co2Kg: dist * 0.15,
    );
  }

  static double haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const earthR = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthR * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
