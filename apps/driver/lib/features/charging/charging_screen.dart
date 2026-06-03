import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/driver_account.dart';
import '../../state/driver_data.dart';

/// Charging tab — real DEWA station map, range awareness, and "I'm charging".
class ChargingScreen extends ConsumerStatefulWidget {
  const ChargingScreen({super.key});

  @override
  ConsumerState<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends ConsumerState<ChargingScreen> {
  bool _busy = false;

  Future<void> _toggleCharging(DriverAccount d, bool charging) async {
    setState(() => _busy = true);
    try {
      await DriverActions.setCharging(charging, d.vehicleId);
      ref.invalidate(currentDriverProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(currentDriverProvider).value;
    final stationsAsync = ref.watch(chargingStationsProvider);
    final charging = driver?.isCharging ?? false;

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
                        child:
                            PlaceholderMap(pickup: DriverMock.driverLocation),
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
            // Charging status + range awareness (real battery/range).
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: charging
                    ? EvcColors.warning.withValues(alpha: 0.12)
                    : EvcColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(EvcRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(charging ? Icons.bolt : Icons.battery_charging_full,
                          color: charging
                              ? EvcColors.warning
                              : EvcColors.primaryDark),
                      const SizedBox(width: 10),
                      Text(
                          charging
                              ? "Charging — you're offline"
                              : '${driver?.batteryPercent ?? 0}% · ${driver?.rangeKm ?? 0} km range',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    charging
                        ? 'Dispatch is paused. Resume when you’re done.'
                        : 'Plug in to keep your range trip-ready.',
                    style: const TextStyle(color: EvcColors.slate),
                  ),
                  const SizedBox(height: 12),
                  if (driver != null)
                    charging
                        ? FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: EvcColors.ink),
                            onPressed: _busy
                                ? null
                                : () => _toggleCharging(driver, false),
                            child: const Text('Done charging'),
                          )
                        : FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _toggleCharging(driver, true),
                            icon: const Icon(Icons.ev_station),
                            label: const Text("I'm charging"),
                          ),
                ],
              ),
            ),
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
                children: [for (final s in stations) _StationCard(station: s)],
              ),
            ),
          ],
        ),
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
  const _StationCard({required this.station});
  final ChargingStation station;

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
                  Text('${station.distanceKm} km · ${station.powerKw} kW',
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
            IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.navigation_outlined)),
          ],
        ),
      ),
    );
  }
}
