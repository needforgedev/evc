import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

// ───────────────────────── helpers ─────────────────────────
const _avatarColors = [
  Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEA580C),
  Color(0xFF0891B2), Color(0xFF65A30D), Color(0xFFDB2777),
];
Color _colorFor(String id) =>
    _avatarColors[id.hashCode.abs() % _avatarColors.length];

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'EV';
  return parts.length == 1
      ? parts.first.substring(0, 1).toUpperCase()
      : (parts[0][0] + parts[1][0]).toUpperCase();
}

String _dateLabel(dynamic iso) {
  final d = iso is String ? DateTime.tryParse(iso)?.toLocal() : null;
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)} · ${two(d.hour)}:${two(d.minute)}';
}

double _mapX(double lng) => ((lng - 55.10) / 0.30).clamp(0.05, 0.95);
double _mapY(double lat) => ((25.30 - lat) / 0.30).clamp(0.05, 0.95);

Future<List<Map<String, dynamic>>> _rows(dynamic builder) async =>
    ((await builder) as List).cast<Map<String, dynamic>>();

// ───────────────────────── drivers ─────────────────────────
final adminDriversProvider = FutureProvider<List<DriverRecord>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;

  final dd = await _rows(client.from('driver_details').select());
  if (dd.isEmpty) return const [];

  final driverIds = dd.map((e) => e['driver_id'] as String).toList();
  final profiles = await _rows(client
      .from('profiles')
      .select('id, full_name, rating, total_trips')
      .inFilter('id', driverIds));
  final pById = {for (final p in profiles) p['id'] as String: p};

  final vehicleIds =
      dd.map((e) => e['current_vehicle_id']).whereType<String>().toList();
  final vehicles = vehicleIds.isEmpty
      ? <Map<String, dynamic>>[]
      : await _rows(client
          .from('vehicles')
          .select('id, model, plate')
          .inFilter('id', vehicleIds));
  final vById = {for (final v in vehicles) v['id'] as String: v};

  final list = [
    for (final d in dd)
      _toRecord(d, pById[d['driver_id']], vById[d['current_vehicle_id']])
  ];
  // Pending first, then by name.
  list.sort((a, b) {
    if (a.status == b.status) return a.name.compareTo(b.name);
    if (a.status == DriverAccountStatus.pending) return -1;
    if (b.status == DriverAccountStatus.pending) return 1;
    return a.name.compareTo(b.name);
  });
  return list;
});

DriverRecord _toRecord(
    Map<String, dynamic> dd, Map<String, dynamic>? p, Map<String, dynamic>? v) {
  final id = dd['driver_id'] as String;
  final name = (p?['full_name'] as String?) ?? 'Driver';
  final status = DriverAccountStatus.values
      .byName((dd['account_status'] as String?) ?? 'pending');
  return DriverRecord(
    id: id,
    name: name,
    initials: _initials(name),
    avatarColor: _colorFor(id),
    rating: (p?['rating'] as num?)?.toDouble() ?? 5.0,
    totalTrips: (p?['total_trips'] as num?)?.toInt() ?? 0,
    vehicleModel: (v?['model'] as String?) ?? '—',
    plate: (v?['plate'] as String?) ??
        (status == DriverAccountStatus.pending ? 'pending' : '—'),
    status: status,
    ownerLabel: (dd['owner_label'] as String?) ?? 'Driver-owned',
    appliedLabel: status == DriverAccountStatus.pending
        ? 'Applied ${_dateLabel(dd['applied_at'])}'
        : '',
  );
}

// ───────────────────────── trips ───────────────────────────
final adminTripsProvider = FutureProvider<List<AdminTrip>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;
  final trips = await _rows(
      client.from('trips').select().order('requested_at', ascending: false));
  if (trips.isEmpty) return const [];

  final ids = <String>{
    for (final t in trips) ...[
      if (t['rider_id'] != null) t['rider_id'] as String,
      if (t['driver_id'] != null) t['driver_id'] as String,
    ]
  }.toList();
  final profiles = await _rows(
      client.from('profiles').select('id, full_name').inFilter('id', ids));
  final nameById = {
    for (final p in profiles) p['id'] as String: (p['full_name'] as String?) ?? '—'
  };

  return [for (final t in trips) _toTrip(t, nameById)];
});

AdminTrip _toTrip(Map<String, dynamic> t, Map<String, String> names) {
  final status = (t['status'] as String?) ?? 'requested';
  return AdminTrip(
    id: t['id'] as String,
    riderName: names[t['rider_id']] ?? '—',
    driverName: t['driver_id'] == null
        ? 'Unassigned'
        : (names[t['driver_id']] ?? '—'),
    fromName: (t['pickup_name'] ?? t['pickup_address'] ?? 'Pickup') as String,
    toName: (t['dest_name'] ?? t['dest_address'] ?? 'Destination') as String,
    tierName: (t['tier_id'] as String?) ?? '',
    fareAed:
        (t['final_fare'] as num?)?.toDouble() ?? (t['fare_estimate'] as num?)?.toDouble() ?? 0,
    status: _tripStatus(status),
    stageLabel: _stageLabel(status),
    etaMinutes: (t['duration_min'] as num?)?.toInt() ?? 0,
    mapX: _mapX((t['pickup_lng'] as num?)?.toDouble() ?? 55.25),
    mapY: _mapY((t['pickup_lat'] as num?)?.toDouble() ?? 25.18),
  );
}

AdminTripStatus _tripStatus(String s) => switch (s) {
      'completed' => AdminTripStatus.completed,
      'canceled' => AdminTripStatus.canceled,
      _ => AdminTripStatus.ongoing,
    };

String _stageLabel(String s) => switch (s) {
      'requested' => 'Finding a driver',
      'matched' => 'Driver assigned',
      'enroute' => 'En route to pickup',
      'arrived' => 'At pickup',
      'ongoing' => 'Trip in progress',
      'completed' => 'Completed',
      'canceled' => 'Canceled',
      _ => s,
    };

// ───────────────────────── fleet ───────────────────────────
final adminFleetProvider = FutureProvider<List<FleetVehicle>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;
  final vehicles = await _rows(client.from('vehicles').select());
  if (vehicles.isEmpty) return const [];

  final dd = await _rows(
      client.from('driver_details').select('driver_id, current_vehicle_id'));
  final driverByVehicle = {
    for (final d in dd)
      if (d['current_vehicle_id'] != null)
        d['current_vehicle_id'] as String: d['driver_id'] as String
  };
  final driverIds = driverByVehicle.values.toList();
  final profiles = driverIds.isEmpty
      ? <Map<String, dynamic>>[]
      : await _rows(client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', driverIds));
  final nameById = {
    for (final p in profiles) p['id'] as String: (p['full_name'] as String?) ?? '—'
  };

  return [
    for (final v in vehicles)
      FleetVehicle(
        plate: (v['plate'] as String?) ?? '—',
        model: (v['model'] as String?) ?? 'EV',
        ownership: OwnershipType.values
            .byName((v['ownership'] as String?) ?? 'driver'),
        batteryPercent: (v['battery_percent'] as num?)?.toInt() ?? 0,
        rangeKm: (v['range_km'] as num?)?.toInt() ?? 0,
        status:
            VehicleStatus.values.byName((v['status'] as String?) ?? 'offline'),
        driverName: nameById[driverByVehicle[v['id']]] ?? 'Unassigned',
        mapX: 0.5,
        mapY: 0.5,
      ),
  ];
});

// Online drivers with a location — markers for the live ops map.
final adminLiveProvider = FutureProvider<List<FleetVehicle>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;
  final locs = await _rows(client.from('driver_locations').select());
  if (locs.isEmpty) return const [];

  final dd = await _rows(
      client.from('driver_details').select('driver_id, current_vehicle_id'));
  final vehById = {for (final d in dd) d['driver_id']: d['current_vehicle_id']};
  final vehicleIds =
      vehById.values.whereType<String>().toList();
  final vehicles = vehicleIds.isEmpty
      ? <Map<String, dynamic>>[]
      : await _rows(client.from('vehicles').select().inFilter('id', vehicleIds));
  final vById = {for (final v in vehicles) v['id'] as String: v};

  return [
    for (final l in locs)
      () {
        final v = vById[vehById[l['driver_id']]];
        return FleetVehicle(
          plate: (v?['plate'] as String?) ?? '—',
          model: (v?['model'] as String?) ?? 'EV',
          ownership: OwnershipType.values
              .byName((v?['ownership'] as String?) ?? 'driver'),
          batteryPercent: (v?['battery_percent'] as num?)?.toInt() ?? 0,
          rangeKm: (v?['range_km'] as num?)?.toInt() ?? 0,
          status: VehicleStatus.values
              .byName((v?['status'] as String?) ?? 'active'),
          driverName: '',
          mapX: _mapX((l['lng'] as num?)?.toDouble() ?? 55.25),
          mapY: _mapY((l['lat'] as num?)?.toDouble() ?? 25.18),
        );
      }()
  ];
});

// ───────────────────────── support ─────────────────────────
final adminTicketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;
  final tickets = await _rows(
      client.from('support_tickets').select().order('created_at', ascending: false));
  if (tickets.isEmpty) return const [];

  final openerIds =
      tickets.map((t) => t['opened_by']).whereType<String>().toList();
  final profiles = await _rows(client
      .from('profiles')
      .select('id, full_name, role')
      .inFilter('id', openerIds));
  final pById = {for (final p in profiles) p['id'] as String: p};

  return [
    for (final t in tickets)
      SupportTicket(
        id: (t['id'] as String).substring(0, 6),
        subject: (t['subject'] as String?) ?? '',
        type: TicketType.values.byName((t['type'] as String?) ?? 'general'),
        fromName:
            '${pById[t['opened_by']]?['full_name'] ?? '—'} (${pById[t['opened_by']]?['role'] ?? ''})',
        status:
            TicketStatus.values.byName((t['status'] as String?) ?? 'open'),
        timeLabel: _dateLabel(t['created_at']),
      ),
  ];
});

// ───────────────────────── actions ─────────────────────────
abstract final class AdminActions {
  static Future<void> setDriverStatus(String driverId, String status) async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.rpc('admin_set_driver_status',
        params: {'p_driver': driverId, 'p_status': status});
  }

  static Future<void> cancelTrip(String tripId) async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.rpc('cancel_trip',
        params: {'p_trip': tripId, 'p_reason': 'Canceled by ops'});
  }
}

// ───────────────────────── config console ─────────────────────────

class AdminPromo {
  const AdminPromo({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.value,
    required this.maxDiscount,
    required this.redemptions,
    required this.active,
  });
  final String id;
  final String code;
  final String? description;
  final String discountType; // 'percent' | 'flat'
  final double value;
  final double? maxDiscount;
  final int redemptions;
  final bool active;
}

class AdminSurge {
  const AdminSurge({
    required this.id,
    required this.zone,
    required this.multiplier,
    required this.active,
  });
  final String id;
  final String zone;
  final double multiplier;
  final bool active;
}

class AdminTier {
  const AdminTier({
    required this.id,
    required this.name,
    required this.multiplier,
    required this.seats,
    required this.active,
  });
  final String id;
  final String name;
  final double multiplier;
  final int seats;
  final bool active;
}

class ConfigChange {
  const ConfigChange({required this.table, required this.action, required this.when});
  final String table;
  final String action;
  final String when;
}

final adminPricingProvider =
    FutureProvider<PricingConfig>((ref) async => EvcPricing.fetchPricing());

final adminTiersProvider = FutureProvider<List<AdminTier>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final rows = await _rows(
      EvcSupabase.client.from('ride_tiers').select().order('sort_order'));
  return rows
      .map((m) => AdminTier(
            id: m['id'] as String,
            name: (m['name'] as String?) ?? (m['id'] as String),
            multiplier: (m['multiplier'] as num?)?.toDouble() ?? 1,
            seats: (m['seats'] as int?) ?? 4,
            active: m['active'] == true,
          ))
      .toList();
});

final adminPromosProvider = FutureProvider<List<AdminPromo>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final rows = await _rows(EvcSupabase.client.from('promo_codes').select().order('code'));
  return rows
      .map((m) => AdminPromo(
            id: m['id'] as String,
            code: m['code'] as String,
            description: m['description'] as String?,
            discountType: (m['discount_type'] as String?) ?? 'percent',
            value: (m['value'] as num?)?.toDouble() ?? 0,
            maxDiscount: (m['max_discount'] as num?)?.toDouble(),
            redemptions: (m['redemptions'] as int?) ?? 0,
            active: m['active'] == true,
          ))
      .toList();
});

final adminSurgesProvider = FutureProvider<List<AdminSurge>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final rows = await _rows(EvcSupabase.client
      .from('surge_rules')
      .select('id, multiplier, active, zones(name)'));
  return rows.map((m) {
    final z = m['zones'];
    return AdminSurge(
      id: m['id'] as String,
      zone: (z is Map ? z['name'] as String? : null) ?? 'Zone',
      multiplier: (m['multiplier'] as num?)?.toDouble() ?? 1,
      active: m['active'] == true,
    );
  }).toList();
});

final adminConfigAuditProvider = FutureProvider<List<ConfigChange>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final rows = await _rows(EvcSupabase.client
      .from('config_audit')
      .select('table_name, action, changed_at')
      .order('changed_at', ascending: false)
      .limit(15));
  return rows
      .map((m) => ConfigChange(
            table: (m['table_name'] as String?) ?? '',
            action: (m['action'] as String?) ?? '',
            when: _dateLabel(m['changed_at']),
          ))
      .toList();
});

abstract final class AdminConfigActions {
  static Future<void> updatePricing({
    required double baseFare,
    required double perKm,
    required double perMin,
    required double minFare,
    required double vatRate,
  }) async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.from('pricing').update({
      'base_fare': baseFare,
      'per_km': perKm,
      'per_min': perMin,
      'min_fare': minFare,
      'vat_rate': vatRate,
    }).eq('region', 'dubai');
  }

  static Future<void> updateTier(String id, {double? multiplier, bool? active}) async {
    if (!EvcSupabase.isReady) return;
    final data = <String, dynamic>{};
    if (multiplier != null) data['multiplier'] = multiplier;
    if (active != null) data['active'] = active;
    if (data.isEmpty) return;
    await EvcSupabase.client.from('ride_tiers').update(data).eq('id', id);
  }

  static Future<void> setPromoActive(String id, bool active) async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.from('promo_codes').update({'active': active}).eq('id', id);
  }

  static Future<void> createPromo({
    required String code,
    String? description,
    required String discountType,
    required double value,
    double? maxDiscount,
  }) async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.from('promo_codes').insert({
      'code': code.toUpperCase(),
      'description': description,
      'discount_type': discountType,
      'value': value,
      'max_discount': maxDiscount,
      'active': true,
    });
  }

  static Future<void> setSurgeActive(String id, bool active) async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.from('surge_rules').update({'active': active}).eq('id', id);
  }
}
