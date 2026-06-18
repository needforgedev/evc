import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/booking_controller.dart';
import '../../state/saved_places_provider.dart';

/// Search / pick a destination. Real Google Places type-ahead (UAE-restricted),
/// with a local saved/recent list when the field is empty and a graceful local
/// fallback when the Places API is unavailable. Pops with the chosen [Place].
class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;

  /// One Places session token per search, reused across keystrokes + the final
  /// details call (groups them into a single billing unit).
  late final String _sessionToken =
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';

  List<EvcPlacePrediction> _predictions = const [];
  String? _searchError; // why live search returned nothing (API not enabled…)
  bool _searching = false; // autocomplete in flight
  bool _resolving = false; // details lookup in flight (after a tap)

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _predictions = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    final r = await EvcPlaces.autocomplete(q, sessionToken: _sessionToken);
    if (!mounted || q != _query.text.trim()) return;
    setState(() {
      _predictions = r.items;
      _searchError = r.error;
      _searching = false;
    });
  }

  Future<void> _pickPrediction(EvcPlacePrediction p) async {
    setState(() => _resolving = true);
    final place =
        await EvcPlaces.details(p.placeId, sessionToken: _sessionToken);
    if (!mounted) return;
    setState(() => _resolving = false);
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load that place.')));
      return;
    }
    Navigator.of(context).pop(place);
  }

  List<Place> _localFilter(List<Place> all) {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedPlacesProvider).value ?? const <SavedPlace>[];
    final hasQuery = _query.text.trim().length >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan your ride')),
      body: SafeArea(
        child: Column(
          children: [
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
                            ref.watch(bookingControllerProvider).pickup.address,
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
                            decoration: InputDecoration(
                              hintText: 'Enter destination',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    )
                                  : null,
                            ),
                            onChanged: _onChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_resolving) const LinearProgressIndicator(minHeight: 2),
            const Divider(height: 1),
            Expanded(
              child: hasQuery
                  ? _results(saved)
                  : _localList([for (final s in saved) s.place, ...MockData.places]),
            ),
          ],
        ),
      ),
    );
  }

  /// Results for an active query: real Google predictions, falling back to the
  /// local saved/mock list when Places returns nothing (e.g. API not enabled).
  Widget _results(List<SavedPlace> saved) {
    if (_predictions.isNotEmpty) {
      return ListView.separated(
        itemCount: _predictions.length,
        separatorBuilder: (_, _) => const Divider(indent: 64, height: 1),
        itemBuilder: (context, i) {
          final p = _predictions[i];
          return ListTile(
            onTap: _resolving ? null : () => _pickPrediction(p),
            leading: const CircleAvatar(
              backgroundColor: EvcColors.mist,
              child: Icon(Icons.place_outlined, color: EvcColors.ink),
            ),
            title: Text(p.primary,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: p.secondary.isEmpty ? null : Text(p.secondary),
            trailing:
                const Icon(Icons.north_west, size: 18, color: EvcColors.slate),
          );
        },
      );
    }
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    // No Google results → local fallback so search still works.
    final local =
        _localFilter([for (final s in saved) s.place, ...MockData.places]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_searchError != null) _errorBanner(_searchError!),
        Expanded(
          child: local.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        _searchError == null
                            ? 'No places found'
                            : 'Live search unavailable — see above.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: EvcColors.slate)),
                  ),
                )
              : _localList(local),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EvcColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(EvcRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Color(0xFFB78000)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Google place search: $message',
                  style: const TextStyle(fontSize: 12, color: EvcColors.ink)),
            ),
          ],
        ),
      );

  Widget _localList(List<Place> results) {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(indent: 64, height: 1),
      itemBuilder: (context, i) {
        final p = results[i];
        return ListTile(
          onTap: () => Navigator.of(context).pop(p),
          leading: CircleAvatar(
            backgroundColor: EvcColors.mist,
            child: Icon(_iconFor(p.kind), color: EvcColors.ink),
          ),
          title:
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(p.address),
          trailing:
              const Icon(Icons.north_west, size: 18, color: EvcColors.slate),
        );
      },
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
