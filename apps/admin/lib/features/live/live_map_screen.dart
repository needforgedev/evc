import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/admin_mock.dart';
import '../../state/admin_data.dart';
import '../../widgets/ops_map.dart';
import '../trips/trip_detail_screen.dart';
import '../trips/trips_screen.dart' show shortId;

/// Live operations map — real fleet markers + ongoing trips.
class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(adminLiveProvider).value ?? const [];
    final ongoing = (ref.watch(adminTripsProvider).value ?? const [])
        .where((t) => t.status == AdminTripStatus.ongoing)
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: OpsMap(fleet: live, hotspots: AdminMock.hotspots),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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
                    child: Text('${live.length} drivers online',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.invalidate(adminLiveProvider);
                        ref.invalidate(adminTripsProvider);
                      },
                    ),
                  ),
                ],
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
                    if (ongoing.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No active trips right now.',
                            style: TextStyle(color: EvcColors.slate)),
                      ),
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
        trailing: Text('#${shortId(trip.id)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: EvcColors.slate)),
      ),
    );
  }
}
