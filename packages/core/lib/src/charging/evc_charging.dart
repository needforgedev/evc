import '../supabase/evc_supabase.dart';

/// A charging session — the EV-charging analog of a trip. `kwh`/`end_pct` are
/// updated live during charging; `cost`/`vat` are set on settle.
class ChargingSession {
  const ChargingSession({
    required this.id,
    required this.stationId,
    required this.status,
    required this.startPct,
    required this.endPct,
    required this.kwh,
    required this.ratePerKwh,
    required this.powerKw,
    required this.targetPct,
    this.cost,
    this.vat,
  });

  final String id;
  final String? stationId;
  final String status; // active | completed
  final int startPct;
  final int endPct;
  final double kwh;
  final double ratePerKwh;
  final int powerKw;
  final int targetPct;
  final double? cost;
  final double? vat;

  bool get isActive => status == 'active';
  double get total => (cost ?? 0) + (vat ?? 0);

  factory ChargingSession.fromRow(Map<String, dynamic> r) => ChargingSession(
        id: r['id'] as String,
        stationId: r['station_id'] as String?,
        status: (r['status'] as String?) ?? 'active',
        startPct: (r['start_pct'] as num?)?.toInt() ?? 0,
        endPct: (r['end_pct'] as num?)?.toInt() ?? 0,
        kwh: (r['kwh'] as num?)?.toDouble() ?? 0,
        ratePerKwh: (r['rate_per_kwh'] as num?)?.toDouble() ?? 0.70,
        powerKw: (r['power_kw'] as num?)?.toInt() ?? 60,
        targetPct: (r['target_pct'] as num?)?.toInt() ?? 100,
        cost: (r['cost'] as num?)?.toDouble(),
        vat: (r['vat'] as num?)?.toDouble(),
      );
}

/// Charging-session operations against Supabase (Phase 1).
abstract final class EvcCharging {
  /// Open a session at [stationId] (takes a stall; driver goes offline).
  static Future<ChargingSession> start(String stationId,
      {int targetPct = 100}) async {
    final r = await EvcSupabase.client.rpc('start_charging',
        params: {'p_station': stationId, 'p_target_pct': targetPct});
    return ChargingSession.fromRow(_row(r));
  }

  /// Persist the (simulated) live meter — kWh delivered + battery %.
  static Future<void> update(String sessionId, double kwh, int pct) =>
      EvcSupabase.client.rpc('update_charging',
          params: {'p_session': sessionId, 'p_kwh': kwh, 'p_pct': pct});

  /// Stop + settle with the final meter reading ([kwh] + battery [pct]) — writes
  /// the session and the vehicle battery/range, so the charge always lands even
  /// if the live ticks were lost. Computes cost (kWh × rate + VAT), frees the stall.
  static Future<ChargingSession> stop(String sessionId,
      {double? kwh, int? pct}) async {
    final r = await EvcSupabase.client.rpc('stop_charging', params: {
      'p_session': sessionId,
      'p_kwh': kwh,
      'p_pct': pct,
    });
    return ChargingSession.fromRow(_row(r));
  }

  static Map<String, dynamic> _row(dynamic r) =>
      (r is List ? r.first : r) as Map<String, dynamic>;
}
