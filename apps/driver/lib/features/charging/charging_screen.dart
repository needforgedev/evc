import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/driver_account.dart';
import '../../state/driver_data.dart';

/// kWh delivered per 1% of battery (~60 kWh pack).
const double _kWhPerPct = 0.6;

/// Grace window (s) after full charge before the idle fee starts (demo-compressed).
const int _graceTotal = 20;

/// Real seconds per accrued idle "minute" (demo-compressed).
const int _idleEverySec = 3;

/// Charging tab — DEWA station map + a real **charging session** (Phase 1):
/// start → simulated live meter (kWh + cost + battery %) → stop & settle.
class ChargingScreen extends ConsumerStatefulWidget {
  const ChargingScreen({super.key});

  @override
  ConsumerState<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends ConsumerState<ChargingScreen> {
  bool _busy = false;

  ChargingSession? _session; // active session
  String _stationName = '';
  double _kwh = 0;
  int _pct = 0;
  bool _full = false;
  Timer? _meter;

  // Grace + idle penalty (after full charge).
  int _graceSecs = 0;
  int _idleMin = 0;
  int _idleAccum = 0;
  Timer? _idle;

  ChargingSession? _receipt; // last completed session (settled)

  @override
  void dispose() {
    _meter?.cancel();
    _idle?.cancel();
    super.dispose();
  }

  // After full charge: a grace window, then the idle fee accrues per minute
  // until the driver unplugs (stops). Demo-compressed.
  void _startGraceIdle() {
    _graceSecs = _graceTotal;
    _idleMin = 0;
    _idleAccum = 0;
    _idle = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_graceSecs > 0) {
        setState(() => _graceSecs--);
      } else {
        _idleAccum++;
        if (_idleAccum >= _idleEverySec) {
          _idleAccum = 0;
          setState(() => _idleMin++);
        }
      }
    });
  }

  // Simulated meter: each 2s tick adds one "minute" of charge at the station's
  // rated power. (No charger hardware — the value is simulated; the session,
  // billing and settle around it are real. Swap this for OCPP MeterValues later.)
  void _tick() {
    final s = _session;
    if (s == null) return;
    var kwh = _kwh + s.powerKw / 60.0;
    var pct = (s.startPct + kwh / _kWhPerPct).round();
    final reachedFull = pct >= s.targetPct;
    if (reachedFull) {
      pct = s.targetPct;
      kwh = (s.targetPct - s.startPct) * _kWhPerPct;
      _meter?.cancel();
    }
    setState(() {
      _kwh = kwh;
      _pct = pct.clamp(0, 100);
      if (reachedFull && !_full) _full = true;
    });
    if (reachedFull && _idle == null) _startGraceIdle();
    EvcCharging.update(s.id, kwh, _pct); // persist (fire-and-forget)
  }

  Future<void> _start(ChargingStation st) async {
    if (st.id == null) return;
    setState(() => _busy = true);
    try {
      final s = await EvcCharging.start(st.id!, targetPct: 100);
      _idle?.cancel();
      setState(() {
        _session = s;
        _stationName = st.name;
        _kwh = s.kwh;
        _pct = s.startPct;
        _full = false;
        _graceSecs = 0;
        _idleMin = 0;
        _idle = null;
        _receipt = null;
      });
      _meter = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
      ref.invalidate(currentDriverProvider);
      ref.invalidate(chargingStationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join(ChargingStation st) async {
    if (st.id == null) return;
    setState(() => _busy = true);
    try {
      await EvcCharging.joinQueue(st.id!);
      ref.invalidate(chargingStationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(String stationId) async {
    setState(() => _busy = true);
    try {
      await EvcCharging.leaveQueue(stationId);
      ref.invalidate(chargingStationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final s = _session;
    if (s == null) return;
    _meter?.cancel();
    _idle?.cancel();
    setState(() => _busy = true);
    try {
      // Pass the final meter reading + idle minutes so settle is exact.
      final done =
          await EvcCharging.stop(s.id, kwh: _kwh, pct: _pct, idleMin: _idleMin);
      setState(() {
        _session = null;
        _receipt = done;
        _full = false;
        _idle = null;
        _idleMin = 0;
        _graceSecs = 0;
      });
      ref.invalidate(currentDriverProvider);
      ref.invalidate(chargingStationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Trailing action for a station card — context-aware (charge / reserve /
  /// join queue / charge-now), and disabled while another intent is active.
  Widget _stationAction(
      ChargingStation s, ChargingQueueEntry? myEntry, bool hasSession) {
    if (hasSession) return const SizedBox.shrink();
    if (myEntry != null) {
      if (myEntry.stationId == s.id && myEntry.isReserved) {
        return FilledButton(
          onPressed: _busy ? null : () => _start(s),
          style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
          child: const Text('Charge now'),
        );
      }
      if (myEntry.stationId == s.id) {
        return const Chip(label: Text('In queue'));
      }
      return const SizedBox.shrink(); // one intent at a time
    }
    if (s.hasAvailability) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: _busy ? null : () => _start(s),
            style: FilledButton.styleFrom(
                minimumSize: const Size(92, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text('Charge'),
          ),
          SizedBox(
            height: 30,
            child: TextButton(
              onPressed: _busy ? null : () => _join(s),
              child: const Text('Reserve'),
            ),
          ),
        ],
      );
    }
    return FilledButton(
      onPressed: _busy ? null : () => _join(s),
      style: FilledButton.styleFrom(
          minimumSize: const Size(96, 40), backgroundColor: EvcColors.ink),
      child: const Text('Join queue'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(currentDriverProvider).value;
    final stationsAsync = ref.watch(chargingStationsProvider);
    final charging = _session != null;

    // My reserve/queue entry (if any), from the realtime queue stream.
    final queue = ref.watch(chargingQueueProvider).value ?? const [];
    final uid = EvcSupabase.currentUserId;
    final mine = uid == null
        ? const <ChargingQueueEntry>[]
        : queue.where((e) => e.driverId == uid).toList();
    final myEntry = mine.isEmpty ? null : mine.first;
    final stations = stationsAsync.value ?? const <ChargingStation>[];
    String stationNameOf(String id) {
      final m = stations.where((s) => s.id == id).toList();
      return m.isEmpty ? 'the station' : m.first.name;
    }

    int myPosition() {
      if (myEntry == null || myEntry.status != 'queued') return 0;
      return queue
              .where((e) =>
                  e.stationId == myEntry.stationId &&
                  e.status == 'queued' &&
                  e.createdAt.isBefore(myEntry.createdAt))
              .length +
          1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Charging')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(EvcRadius.md),
              child: SizedBox(
                height: 180,
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      const Positioned.fill(
                        child: PlaceholderMap(pickup: DriverMock.driverLocation),
                      ),
                      for (final s in stationsAsync.value ?? const [])
                        Positioned(
                          left: s.mapX * c.maxWidth - 16,
                          top: s.mapY * c.maxHeight - 16,
                          child: _StationPin(available: s.hasAvailability),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active session → live meter; else last receipt; else a hint.
            if (charging)
              _ActivePanel(
                station: _stationName,
                kwh: _kwh,
                pct: _pct,
                ratePerKwh: _session!.ratePerKwh,
                targetPct: _session!.targetPct,
                full: _full,
                graceSecs: _graceSecs,
                idleMin: _idleMin,
                idleFeePerMin: _session!.idleFeePerMin,
                busy: _busy,
                onStop: _busy ? null : _stop,
              )
            else if (myEntry != null)
              _QueuePanel(
                reserved: myEntry.isReserved,
                station: stationNameOf(myEntry.stationId),
                position: myPosition(),
                busy: _busy,
                onLeave: _busy ? null : () => _leave(myEntry.stationId),
              )
            else if (_receipt != null)
              _ReceiptCard(
                  session: _receipt!,
                  onDone: () => setState(() => _receipt = null))
            else
              _RangeHint(
                  battery: driver?.batteryPercent ?? 0,
                  range: driver?.rangeKm ?? 0),

            const SizedBox(height: 20),
            const Text('Nearby chargers',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            stationsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load stations.\n$e'),
              data: (stations) => Column(
                children: [
                  for (final s in stations)
                    _StationCard(
                      station: s,
                      action: _stationAction(s, myEntry, charging),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live charging session — simulated meter + running cost.
class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    required this.station,
    required this.kwh,
    required this.pct,
    required this.ratePerKwh,
    required this.targetPct,
    required this.full,
    required this.graceSecs,
    required this.idleMin,
    required this.idleFeePerMin,
    required this.busy,
    required this.onStop,
  });

  final String station;
  final double kwh;
  final int pct;
  final double ratePerKwh;
  final int targetPct;
  final bool full;
  final int graceSecs;
  final int idleMin;
  final double idleFeePerMin;
  final bool busy;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final cost = kwh * ratePerKwh;
    final idling = full && graceSecs <= 0 && idleMin > 0;
    final idleFee = idleMin * idleFeePerMin;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvcColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EvcRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: EvcColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(full ? 'Fully charged' : 'Charging — $station',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Text('$pct%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / targetPct).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: EvcColors.line,
              color: full ? EvcColors.primary : EvcColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric('${kwh.toStringAsFixed(1)} kWh', 'Delivered'),
              _divider(),
              _metric('AED ${cost.toStringAsFixed(2)}', 'Running cost'),
              _divider(),
              _metric('AED ${ratePerKwh.toStringAsFixed(2)}', 'per kWh'),
            ],
          ),
          const SizedBox(height: 8),
          if (idling)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: EvcColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(EvcRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: EvcColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Idle $idleMin min · +AED ${idleFee.toStringAsFixed(2)} — unplug to stop the fee',
                        style: const TextStyle(
                            color: EvcColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            Text(
              !full
                  ? 'Dispatch is paused while you charge.'
                  : graceSecs > 0
                      ? 'Fully charged · move within 0:${graceSecs.toString().padLeft(2, '0')} to avoid an idle fee.'
                      : 'Fully charged — stop to free the stall and settle.',
              style: const TextStyle(color: EvcColors.slate, fontSize: 13),
            ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EvcColors.ink),
            onPressed: onStop,
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Stop & settle'),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
          ],
        ),
      );

  Widget _divider() => Container(
      width: 1, height: 30, color: EvcColors.line,
      margin: const EdgeInsets.symmetric(horizontal: 10));
}

/// Settled-session receipt.
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.session, required this.onDone});
  final ChargingSession session;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final vat = session.vat ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvcColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(EvcRadius.md),
        border: Border.all(color: EvcColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: EvcColors.primaryDark),
              SizedBox(width: 10),
              Text('Charging complete',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _row('Energy', '${session.kwh.toStringAsFixed(1)} kWh'),
          _row('Charge', '${session.startPct}% → ${session.endPct}%'),
          _row('Rate', 'AED ${session.ratePerKwh.toStringAsFixed(2)}/kWh'),
          _row('Energy cost', 'AED ${session.energyCost.toStringAsFixed(2)}'),
          if (session.idleFee > 0)
            _row('Idle fee (${session.idleMin} min)',
                'AED ${session.idleFee.toStringAsFixed(2)}'),
          _row('VAT', 'AED ${vat.toStringAsFixed(2)}'),
          const Divider(height: 18),
          _row('Total', 'AED ${session.total.toStringAsFixed(2)}', bold: true),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onDone, child: const Text('Done')),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: bold ? EvcColors.ink : EvcColors.slate,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    fontSize: bold ? 16 : 14)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 16 : 14)),
          ],
        ),
      );
}

/// Idle hint when not charging.
class _RangeHint extends StatelessWidget {
  const _RangeHint({required this.battery, required this.range});
  final int battery;
  final int range;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EvcColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(EvcRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.battery_charging_full, color: EvcColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$battery% · $range km range',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                const Text('Pick a nearby charger and tap Charge.',
                    style: TextStyle(color: EvcColors.slate)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationPin extends StatelessWidget {
  const _StationPin({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: available ? EvcColors.primary : EvcColors.danger,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.ev_station, color: Colors.white, size: 16),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.action});
  final ChargingStation station;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final available = station.hasAvailability;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: EvcColors.mist,
                borderRadius: BorderRadius.circular(EvcRadius.sm),
              ),
              child: const Icon(Icons.ev_station, color: EvcColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                      '${station.distanceKm.toStringAsFixed(1)} km · ${station.powerKw} kW · AED ${station.pricePerKwh.toStringAsFixed(2)}/kWh',
                      style: const TextStyle(
                          color: EvcColors.slate, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (available ? EvcColors.primary : EvcColors.danger)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      available
                          ? '${station.availableStalls}/${station.totalStalls} available'
                          : 'Full',
                      style: TextStyle(
                          color: available
                              ? EvcColors.primaryDark
                              : EvcColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }
}

/// Reserve / queue status banner.
class _QueuePanel extends StatelessWidget {
  const _QueuePanel({
    required this.reserved,
    required this.station,
    required this.position,
    required this.busy,
    required this.onLeave,
  });

  final bool reserved;
  final String station;
  final int position;
  final bool busy;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    final color = reserved ? EvcColors.primary : EvcColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EvcRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(reserved ? Icons.ev_station : Icons.hourglass_bottom,
                  color: reserved ? EvcColors.primaryDark : EvcColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    reserved
                        ? 'Stall reserved at $station'
                        : 'In queue at $station',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reserved
                ? 'Tap Charge now on the station — held ~10 min.'
                : 'Position $position — we’ll hold a stall when it’s your turn.',
            style: const TextStyle(color: EvcColors.slate, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onLeave,
            child: Text(reserved ? 'Cancel reservation' : 'Leave queue'),
          ),
        ],
      ),
    );
  }
}
