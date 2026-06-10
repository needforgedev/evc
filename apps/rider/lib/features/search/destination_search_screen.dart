import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/saved_places_provider.dart';

/// Search / pick a destination. Pops with the chosen [Place].
class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final _query = TextEditingController();

  List<Place> _filter(List<Place> all) {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedPlacesProvider).value ?? const <SavedPlace>[];
    final results =
        _filter([for (final s in saved) s.place, ...MockData.places]);
    return Scaffold(
      appBar: AppBar(title: const Text('Plan your ride')),
      body: SafeArea(
        child: Column(
          children: [
            // Pickup + destination stacked fields.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EvcColors.surface,
                  borderRadius: BorderRadius.circular(EvcRadius.md),
                  border: Border.all(color: EvcColors.line),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const _Dot(color: EvcColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            MockData.currentLocation.address,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: SizedBox(
                        height: 22,
                        child: VerticalDivider(width: 2),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: EvcColors.ink, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _query,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter destination',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, _) =>
                    const Divider(indent: 64, height: 1),
                itemBuilder: (context, i) {
                  final p = results[i];
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(p),
                    leading: CircleAvatar(
                      backgroundColor: EvcColors.mist,
                      child: Icon(_iconFor(p.kind), color: EvcColors.ink),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(p.address),
                    trailing: const Icon(Icons.north_west,
                        size: 18, color: EvcColors.slate),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PlaceKind kind) => switch (kind) {
        PlaceKind.home => Icons.home_outlined,
        PlaceKind.work => Icons.work_outline,
        PlaceKind.recent => Icons.history,
        PlaceKind.search || PlaceKind.pin => Icons.place_outlined,
      };
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
    );
  }
}