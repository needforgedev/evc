import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/driver_status_controller.dart';

/// Charging tab — station map, "I'm charging" status, and nearby DEWA chargers.
class ChargingScreen extends ConsumerWidget {
  const ChargingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = ref.watch(driverStatusProvider);
    final charging = driver.isCharging;

    return Scaffold(
      appBar: AppBar(title: const Text('Charging')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            // Map header with station markers.
            ClipRRect(
              borderRadius: BorderRadius.circular(EvcRadius.md),
              child: SizedBox(
                height: 180,
                child: LayoutBuilder(
                  builder: (context, c) {
                    return Stack(
                      children: [
                        const Positioned.fill(
                          child: PlaceholderMap(
                              pickup: DriverMock.driverLocation),
                        ),
                        for (final s in DriverMock.stations)
                          Positioned(
                            left: s.mapX * c.maxWidth - 16,
                            top: s.mapY * c.maxHeight - 16,
                            child: _StationPin(available: s.hasAvailability),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Charging status / range awareness.
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
                      Icon(
                          charging
                              ? Icons.bolt
                              : Icons.battery_charging_full,
                          color: charging
                              ? EvcColors.warning
                              : EvcColors.primaryDark),
                      const SizedBox(width: 10),
                      Text(
                          charging
                              ? 'Charging — you\'re offline'
                              : '${driver.batteryPercent}% · ${driver.rangeKm} km range',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    charging
                        ? 'Dispatch is paused. Resume when you\'re done.'
                        : 'Good for ~6 more trips. Consider a top-up within 2 hours.',
                    style: const TextStyle(color: EvcColors.slate),
                  ),
                  const SizedBox(height: 12),
                  charging
                      ? FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: EvcColors.ink),
                          onPressed: () => ref
                              .read(driverStatusProvider.notifier)
                              .stopCharging(),
                          child: const Text('Done charging — go offline'),
                        )
                      : FilledButton.icon(
                          onPressed: () => ref
                              .read(driverStatusProvider.notifier)
                              .startCharging(),
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
            for (final s in DriverMock.stations) _StationCard(station: s),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
              icon: const Icon(Icons.navigation_outlined),
            ),
          ],
        ),
      ),
    );
  }
}