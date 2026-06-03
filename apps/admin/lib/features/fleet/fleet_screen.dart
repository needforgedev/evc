import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';

/// Fleet registry — every EV, its battery/range, ownership and status (real).
class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetAsync = ref.watch(adminFleetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fleet & vehicles')),
      body: SafeArea(
        top: false,
        child: fleetAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load fleet.\n$e')),
          data: (fleet) {
            if (fleet.isEmpty) {
              return const Center(
                  child: Text('No vehicles yet.',
                      style: TextStyle(color: EvcColors.slate)));
            }
            int countOf(VehicleStatus s) =>
                fleet.where((v) => v.status == s).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  children: [
                    _tally('${fleet.length}', 'Vehicles'),
                    _tally('${countOf(VehicleStatus.active)}', 'Active'),
                    _tally('${countOf(VehicleStatus.charging)}', 'Charging'),
                    _tally('${countOf(VehicleStatus.maintenance)}', 'Service'),
                  ],
                ),
                const SizedBox(height: 20),
                for (final v in fleet) _VehicleCard(vehicle: v),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tally(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          Text(label,
              style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});
  final FleetVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (vehicle.status) {
      VehicleStatus.active => ('Active', EvcColors.primaryDark),
      VehicleStatus.charging => ('Charging', EvcColors.warning),
      VehicleStatus.maintenance => ('Maintenance', EvcColors.danger),
      VehicleStatus.offline => ('Offline', EvcColors.slate),
    };
    final battery = vehicle.batteryPercent;
    final batteryColor = battery >= 50
        ? EvcColors.primary
        : battery >= 20
            ? EvcColors.warning
            : EvcColors.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${vehicle.model} · ${vehicle.plate}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                          '${vehicle.driverName} · ${vehicle.ownership == OwnershipType.company ? 'Company-owned' : 'Driver-owned'}',
                          style: const TextStyle(
                              color: EvcColors.slate, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: battery / 100,
                      minHeight: 8,
                      backgroundColor: EvcColors.line,
                      color: batteryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$battery% · ${vehicle.rangeKm} km',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
