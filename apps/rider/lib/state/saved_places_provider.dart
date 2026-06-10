import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

import '../mock/mock_data.dart';

/// The rider's saved places (Home / Work / custom), real from `saved_places`;
/// falls back to mock shortcuts when the backend isn't configured.
final savedPlacesProvider = FutureProvider<List<SavedPlace>>((ref) async {
  if (!EvcSupabase.isReady) {
    return [
      for (final p in MockData.savedPlaces)
        SavedPlace(id: 'mock-${p.kind.name}', place: p),
    ];
  }
  return EvcSavedPlaces.list();
});
