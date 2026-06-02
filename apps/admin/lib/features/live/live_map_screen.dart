import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/admin_mock.dart';
import '../../state/admin_controller.dart';
import '../../widgets/ops_map.dart';
import '../trips/trip_detail_screen.dart';

/// Live operations map — fleet, demand hotspots, and a sheet of ongoing trips.
class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoing = ref.watch(adminControllerProvider).ongoing;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: OpsMap(fleet: AdminMock.fleet, hotspots: AdminMock.hotspots),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(EvcRadius.lg),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Legend(color: EvcColors.primary, label: 'Active'),
                    SizedBox(width: 12),
                    _Legend(color: EvcColors.warning, label: 'Charging'),
                    SizedBox(width: 12),
                    _Legend(color: EvcColors.danger, label: 'Maintenance'),
                  ],
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.16,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: EvcColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, -4)),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: EvcColors.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('${ongoing.length} ongoing trips',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    for (final t in ongoing) _TripTile(trip: t),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});
  final AdminTrip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        ),
        leading: const CircleAvatar(
          backgroundColor: EvcColors.mist,
          child: Icon(Icons.local_taxi, color: EvcColors.ink),
        ),
        title: Text('${trip.riderName} → ${trip.toName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${trip.driverName} · ${trip.stageLabel}'),
        trailing: Text('${trip.etaMinutes}m',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: EvcColors.slate)),
      ),
    );
  }
}