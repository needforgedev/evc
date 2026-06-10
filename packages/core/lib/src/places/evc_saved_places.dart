import '../models/place.dart';
import '../supabase/evc_supabase.dart';

/// A rider's saved place (a [Place] plus its DB row id, for delete).
class SavedPlace {
  const SavedPlace({required this.id, required this.place});
  final String id;
  final Place place;
}

/// CRUD over the `saved_places` table (RLS: rider owns their own rows).
abstract final class EvcSavedPlaces {
  static PlaceKind _kind(String? s) => switch (s) {
        'home' => PlaceKind.home,
        'work' => PlaceKind.work,
        'recent' => PlaceKind.recent,
        'search' => PlaceKind.search,
        _ => PlaceKind.pin,
      };

  static Future<List<SavedPlace>> list() async {
    if (!EvcSupabase.isReady || !EvcSupabase.hasSession) return const [];
    final rows = await EvcSupabase.client
        .from('saved_places')
        .select()
        .order('created_at');
    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      return SavedPlace(
        id: m['id'] as String,
        place: Place(
          name: (m['name'] as String?) ?? 'Saved place',
          address: (m['address'] as String?) ?? '',
          kind: _kind(m['kind'] as String?),
          lat: (m['lat'] as num?)?.toDouble() ?? 0,
          lng: (m['lng'] as num?)?.toDouble() ?? 0,
        ),
      );
    }).toList();
  }

  /// Adds a saved place. Home and Work are unique per rider — re-adding either
  /// replaces the previous one.
  static Future<void> add({
    required PlaceKind kind,
    required String name,
    required String address,
    required double lat,
    required double lng,
  }) async {
    final uid = EvcSupabase.currentUserId;
    if (uid == null) return;
    final client = EvcSupabase.client;
    if (kind == PlaceKind.home || kind == PlaceKind.work) {
      await client
          .from('saved_places')
          .delete()
          .eq('rider_id', uid)
          .eq('kind', kind.name);
    }
    await client.from('saved_places').insert({
      'rider_id': uid,
      'kind': kind.name,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
    });
  }

  static Future<void> remove(String id) async {
    if (!EvcSupabase.isReady) return;
    await EvcSupabase.client.from('saved_places').delete().eq('id', id);
  }
}
