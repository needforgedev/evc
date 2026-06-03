import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';
import 'trip_detail_screen.dart';

String shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

/// Trip search + monitoring (real data).
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  final _query = TextEditingController();
  int _filter = 0; // 0 all, 1 ongoing, 2 completed, 3 canceled

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matchesFilter(AdminTrip t) => switch (_filter) {
        1 => t.status == AdminTripStatus.ongoing,
        2 => t.status == AdminTripStatus.completed,
        3 => t.status == AdminTripStatus.canceled,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(adminTripsProvider);
    final q = _query.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Trips'), actions: [
        IconButton(
            onPressed: () => ref.invalidate(adminTripsProvider),
            icon: const Icon(Icons.refresh)),
      ]),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search ID, rider, driver, destination',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final (i, label) in const [
                    (0, 'All'),
                    (1, 'Ongoing'),
                    (2, 'Completed'),
                    (3, 'Canceled'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _filter == i,
                        showCheckmark: false,
                        selectedColor:
                            EvcColors.primary.withValues(alpha: 0.16),
                        onSelected: (_) => setState(() => _filter = i),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tripsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load trips.\n$e')),
                data: (trips) {
                  final results = trips.where((t) {
                    if (!_matchesFilter(t)) return false;
                    if (q.isEmpty) return true;
                    return t.id.toLowerCase().contains(q) ||
                        t.riderName.toLowerCase().contains(q) ||
                        t.driverName.toLowerCase().contains(q) ||
                        t.toName.toLowerCase().contains(q);
                  }).toList();
                  if (results.isEmpty) {
                    return const Center(
                        child: Text('No trips.',
                            style: TextStyle(color: EvcColors.slate)));
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [for (final t in results) _TripCard(trip: t)],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final AdminTrip trip;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (trip.status) {
      AdminTripStatus.ongoing => ('Ongoing', EvcColors.primaryDark),
      AdminTripStatus.completed => ('Completed', EvcColors.slate),
      AdminTripStatus.canceled => ('Canceled', EvcColors.danger),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        ),
        borderRadius: BorderRadius.circular(EvcRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${shortId(trip.id)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${trip.riderName} → ${trip.toName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text('${trip.driverName} · ${trip.tierName} · AED ${trip.fareAed.toStringAsFixed(2)}',
                  style:
                      const TextStyle(color: EvcColors.slate, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
