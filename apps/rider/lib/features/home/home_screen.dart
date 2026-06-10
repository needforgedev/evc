import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/booking_controller.dart';
import '../../state/saved_places_provider.dart';
import '../booking/ride_options_screen.dart';
import '../places/saved_places_screen.dart';
import '../profile/profile_screen.dart';
import 'package:evc_maps/evc_maps.dart';

import '../search/destination_search_screen.dart';

/// Home — map + "where to?" booking entry point.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _chooseDestination(BuildContext context, WidgetRef ref,
      {Place? preset}) async {
    final place = preset ??
        await Navigator.of(context).push<Place>(
          MaterialPageRoute(builder: (_) => const DestinationSearchScreen()),
        );
    if (place == null || !context.mounted) return;
    ref.read(bookingControllerProvider.notifier).setDestination(place);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RideOptionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickup = ref.watch(bookingControllerProvider).pickup;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: PlaceholderMap(pickup: pickup)),
          // Top controls.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.person_outline,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    ),
                  ),
                  const Spacer(),
                  Container(
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
                        Icon(Icons.eco_rounded,
                            color: EvcColors.primaryDark, size: 16),
                        SizedBox(width: 6),
                        Text('100% electric',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom booking panel.
          Align(
            alignment: Alignment.bottomCenter,
            child: _BookingPanel(
              savedPlaces: ref.watch(savedPlacesProvider).value ?? const [],
              onWhereTo: () => _chooseDestination(context, ref),
              onSaved: (p) => _chooseDestination(context, ref, preset: p),
              onManage: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedPlacesScreen()),
                );
                ref.invalidate(savedPlacesProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: EvcColors.ink),
        ),
      ),
    );
  }
}

class _BookingPanel extends StatelessWidget {
  const _BookingPanel({
    required this.savedPlaces,
    required this.onWhereTo,
    required this.onSaved,
    required this.onManage,
  });

  final List<SavedPlace> savedPlaces;
  final VoidCallback onWhereTo;
  final ValueChanged<Place> onSaved;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Text(
                'Where are you going?',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              // "Where to?" search field.
              InkWell(
                onTap: onWhereTo,
                borderRadius: BorderRadius.circular(EvcRadius.sm),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: EvcColors.mist,
                    borderRadius: BorderRadius.circular(EvcRadius.sm),
                    border: Border.all(color: EvcColors.line),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: EvcColors.slate),
                      SizedBox(width: 12),
                      Text('Where to?',
                          style:
                              TextStyle(color: EvcColors.slate, fontSize: 16)),
                      Spacer(),
                      Icon(Icons.schedule, color: EvcColors.slate, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final sp in savedPlaces.take(2)) ...[
                    _SavedChip(place: sp.place, onTap: () => onSaved(sp.place)),
                    const SizedBox(width: 10),
                  ],
                  _ManageChip(onTap: onManage),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedChip extends StatelessWidget {
  const _SavedChip({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EvcRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: EvcColors.mist,
          borderRadius: BorderRadius.circular(EvcRadius.sm),
          border: Border.all(color: EvcColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                switch (place.kind) {
                  PlaceKind.home => Icons.home_outlined,
                  PlaceKind.work => Icons.work_outline,
                  _ => Icons.bookmark_outline,
                },
                size: 18,
                color: EvcColors.ink),
            const SizedBox(width: 8),
            Text(place.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ManageChip extends StatelessWidget {
  const _ManageChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EvcRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: EvcColors.mist,
          borderRadius: BorderRadius.circular(EvcRadius.sm),
          border: Border.all(color: EvcColors.line),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: EvcColors.ink),
            SizedBox(width: 6),
            Text('Saved', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}