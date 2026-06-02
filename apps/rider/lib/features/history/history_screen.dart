import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';

/// Past trips with a running CO₂-saved total.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = MockData.history;
    final totalCo2 =
        trips.fold<double>(0, (sum, t) => sum + t.co2SavedKg);

    return Scaffold(
      appBar: AppBar(title: const Text('Your trips')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EvcColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(EvcRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded,
                      color: EvcColors.primaryDark, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${totalCo2.toStringAsFixed(1)} kg CO₂ saved',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const Text('vs. equivalent petrol trips',
                            style: TextStyle(color: EvcColors.slate)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final t in trips) ...[
              _TripRow(trip: t),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});
  final TripHistoryEntry trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(trip.dateLabel,
                    style: const TextStyle(
                        color: EvcColors.slate,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                Text('AED ${trip.fareAed.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            _leg(Icons.radio_button_checked, EvcColors.primary, trip.fromName),
            const Padding(
              padding: EdgeInsets.only(left: 9),
              child: SizedBox(height: 16, child: VerticalDivider(width: 2)),
            ),
            _leg(Icons.location_on, EvcColors.ink, trip.toName),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(trip.tierName),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Co2Badge(kg: trip.co2SavedKg, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _leg(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}