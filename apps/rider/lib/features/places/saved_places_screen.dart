import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/saved_places_provider.dart';
import '../search/destination_search_screen.dart';

/// Manage saved places — Home / Work / custom (real `saved_places`).
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  IconData _iconFor(PlaceKind kind) => switch (kind) {
        PlaceKind.home => Icons.home_outlined,
        PlaceKind.work => Icons.work_outline,
        _ => Icons.bookmark_outline,
      };

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final place = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => const DestinationSearchScreen()),
    );
    if (place == null || !context.mounted) return;

    final kind = await showModalBottomSheet<PlaceKind>(
      context: context,
      backgroundColor: EvcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Save "${place.name}" as',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: EvcColors.ink),
              title: const Text('Home'),
              onTap: () => Navigator.of(sheet).pop(PlaceKind.home),
            ),
            ListTile(
              leading: const Icon(Icons.work_outline, color: EvcColors.ink),
              title: const Text('Work'),
              onTap: () => Navigator.of(sheet).pop(PlaceKind.work),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline, color: EvcColors.ink),
              title: const Text('Save as place'),
              onTap: () => Navigator.of(sheet).pop(PlaceKind.pin),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (kind == null) return;

    final name = switch (kind) {
      PlaceKind.home => 'Home',
      PlaceKind.work => 'Work',
      _ => place.name,
    };
    try {
      await EvcSavedPlaces.add(
        kind: kind,
        name: name,
        address: place.address,
        lat: place.lat,
        lng: place.lng,
      );
      ref.invalidate(savedPlacesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  Future<void> _remove(WidgetRef ref, String id) async {
    try {
      await EvcSavedPlaces.remove(id);
      ref.invalidate(savedPlacesProvider);
    } catch (_) {/* ignore */}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedPlacesProvider);
    final places = async.value ?? const <SavedPlace>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add place'),
      ),
      body: async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : places.isEmpty
              ? const _Empty()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: places.length,
                  separatorBuilder: (_, _) =>
                      const Divider(indent: 64, height: 1),
                  itemBuilder: (context, i) {
                    final sp = places[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: EvcColors.mist,
                        child: Icon(_iconFor(sp.place.kind),
                            color: EvcColors.ink),
                      ),
                      title: Text(sp.place.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(sp.place.address),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: EvcColors.slate),
                        onPressed: () => _remove(ref, sp.id),
                      ),
                    );
                  },
                ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 48, color: EvcColors.slate),
            SizedBox(height: 12),
            Text('No saved places yet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(height: 4),
            Text('Add Home, Work, or any spot for one-tap booking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EvcColors.slate)),
          ],
        ),
      ),
    );
  }
}
