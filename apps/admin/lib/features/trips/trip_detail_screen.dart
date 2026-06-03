import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';
import 'trips_screen.dart' show shortId;

/// Inspect a single trip + intervene (reassign / cancel / refund).
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.trip});

  final AdminTrip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(adminTripsProvider).value?.firstWhere(
              (t) => t.id == trip.id,
              orElse: () => trip,
            ) ??
        trip;
    final ongoing = current.status == AdminTripStatus.ongoing;

    void snack(String m) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));

    return Scaffold(
      appBar: AppBar(title: Text('#${shortId(current.id)}')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(EvcRadius.md),
                    child: SizedBox(
                      height: 160,
                      child: LayoutBuilder(
                        builder: (context, c) => Stack(
                          children: [
                            const Positioned.fill(child: PlaceholderMap()),
                            Positioned(
                              left: current.mapX * c.maxWidth - 17,
                              top: current.mapY * c.maxHeight - 17,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: ongoing
                                      ? EvcColors.primary
                                      : EvcColors.slate,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                ),
                                child: const Icon(Icons.local_taxi,
                                    color: Colors.white, size: 17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(current.stageLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 16),
                  _row('Rider', current.riderName, Icons.person_outline),
                  _row('Driver', current.driverName, Icons.badge_outlined),
                  _row('From', current.fromName, Icons.my_location),
                  _row('To', current.toName, Icons.location_on_outlined),
                  _row('Tier', current.tierName, Icons.directions_car_outlined),
                  _row('Fare', 'AED ${current.fareAed.toStringAsFixed(2)}',
                      Icons.payments_outlined),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: ongoing
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => snack('Reassigning to nearest EV…'),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Reassign'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: EvcColors.danger),
                            onPressed: () async {
                              try {
                                await AdminActions.cancelTrip(current.id);
                                ref.invalidate(adminTripsProvider);
                                if (context.mounted) {
                                  snack('Trip canceled');
                                }
                              } catch (e) {
                                if (context.mounted) snack('Failed: $e');
                              }
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel'),
                          ),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: () => snack('Refund issued to rider'),
                      icon: const Icon(Icons.replay),
                      label: const Text('Issue refund'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: EvcColors.slate),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(color: EvcColors.slate, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
