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
    required this.idleFeePerMin,
    this.cost,
    this.vat,
    this.idleMin = 0,
    this.idleFee = 0,
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

  /// Idle fee charged per minute after the grace period (AED/min).
  final double idleFeePerMin;
  final int idleMin;
  final double idleFee;
  final double? cost;
  final double? vat;

  bool get isActive => status == 'active';
  double get energyCost => (cost ?? 0) - idleFee;
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
        idleFeePerMin: (r['idle_fee_per_min'] as num?)?.toDouble() ?? 1.00,
        idleMin: (r['idle_min'] as num?)?.toInt() ?? 0,
        idleFee: (r['idle_fee'] as num?)?.toDouble() ?? 0,
        cost: (r['cost'] as num?)?.toDouble(),
        vat: (r['vat'] as num?)?.toDouble(),
      );
}

/// A driver's reserve/queue entry at a station.
class ChargingQueueEntry {
  const ChargingQueueEntry({
    required this.id,
    required this.stationId,
    required this.driverId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String stationId;
  final String driverId;
  final String status; // queued | reserved
  final DateTime createdAt;

  bool get isReserved => status == 'reserved';

  factory ChargingQueueEntry.fromRow(Map<String, dynamic> r) =>
      ChargingQueueEntry(
        id: r['id'] as String,
        stationId: r['station_id'] as String,
        driverId: r['driver_id'] as String,
        status: (r['status'] as String?) ?? 'queued',
        createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
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
      {double? kwh, int? pct, int idleMin = 0}) async {
    final r = await EvcSupabase.client.rpc('stop_charging', params: {
      'p_session': sessionId,
      'p_kwh': kwh,
      'p_pct': pct,
      'p_idle_min': idleMin,
    });
    return ChargingSession.fromRow(_row(r));
  }

  // ── reserve / queue (CHG-02) ──────────────────────────────────
  /// Reserve a free stall, or join the queue if the station is full.
  static Future<ChargingQueueEntry> joinQueue(String stationId) async {
    final r = await EvcSupabase.client
        .rpc('join_charging_queue', params: {'p_station': stationId});
    return ChargingQueueEntry.fromRow(_row(r));
  }

  static Future<void> leaveQueue(String stationId) => EvcSupabase.client
      .rpc('leave_charging_queue', params: {'p_station': stationId});

  /// Realtime stream of all reserve/queue entries (drivers compute their own
  /// status + live position from this).
  static Stream<List<ChargingQueueEntry>> queueStream() {
    return EvcSupabase.client
        .from('charging_queue')
        .stream(primaryKey: ['id']).map(
            (rows) => [for (final r in rows) ChargingQueueEntry.fromRow(r)]);
  }

  // ── admin (ADM-05) ────────────────────────────────────────────
  static Future<void> adminSetStationRate(String stationId, double rate) =>
      EvcSupabase.client.rpc('admin_set_station_rate',
          params: {'p_station': stationId, 'p_rate': rate});

  static Map<String, dynamic> _row(dynamic r) =>
      (r is List ? r.first : r) as Map<String, dynamic>;
}
