import 'package:evc_core/evc_core.dart';

/// One Google Places autocomplete suggestion.
class EvcPlacePrediction {
  const EvcPlacePrediction({
    required this.placeId,
    required this.primary,
    required this.secondary,
  });

  final String placeId;

  /// Main line (e.g. "Museum of the Future").
  final String primary;

  /// Secondary line (e.g. "Sheikh Zayed Road, Dubai").
  final String secondary;
}

/// Autocomplete result: the suggestions plus an optional human-readable error
/// so the UI can explain why live search returned nothing.
class EvcAutocompleteResult {
  const EvcAutocompleteResult(this.items, {this.error});
  final List<EvcPlacePrediction> items;
  final String? error;
}

/// Google **Places (New)** wrapper: type-ahead suggestions + resolving a pick to
/// real coordinates (UAE-restricted, Dubai-biased).
///
/// Routes through the `maps-proxy` Supabase edge function so the Google key
/// stays server-side (PRD #5) — never shipped in the client.
class EvcPlaces {
  const EvcPlaces._();

  static Future<EvcAutocompleteResult> autocomplete(
    String input, {
    String? sessionToken,
  }) async {
    if (input.trim().length < 2) return const EvcAutocompleteResult([]);
    if (!EvcSupabase.isReady) {
      return const EvcAutocompleteResult([], error: 'Backend not configured.');
    }

    try {
      final res = await EvcSupabase.client.functions.invoke('maps-proxy', body: {
        'op': 'autocomplete',
        'input': input.trim(),
        'sessionToken': sessionToken,
      });
      final data = res.data as Map<String, dynamic>?;
      final gStatus = (data?['status'] as num?)?.toInt() ?? 0;
      final body = data?['body'] as Map<String, dynamic>?;
      if (gStatus != 200 || body == null) {
        final msg = (body?['error'] as Map<String, dynamic>?)?['message'] as String?;
        return EvcAutocompleteResult(const [],
            error: msg ?? 'Places error $gStatus');
      }

      final sugg = body['suggestions'] as List<dynamic>? ?? const [];
      final items = <EvcPlacePrediction>[];
      for (final raw in sugg) {
        final pp = (raw as Map<String, dynamic>)['placePrediction']
            as Map<String, dynamic>?;
        if (pp == null) continue;
        final id = pp['placeId'] as String?;
        if (id == null || id.isEmpty) continue;
        final sf = pp['structuredFormat'] as Map<String, dynamic>?;
        final main = (sf?['mainText'] as Map<String, dynamic>?)?['text'] as String?;
        final sec =
            (sf?['secondaryText'] as Map<String, dynamic>?)?['text'] as String?;
        final text = (pp['text'] as Map<String, dynamic>?)?['text'] as String?;
        items.add(EvcPlacePrediction(
          placeId: id,
          primary: main ?? text ?? '',
          secondary: sec ?? '',
        ));
      }
      return EvcAutocompleteResult(items);
    } catch (_) {
      return const EvcAutocompleteResult([], error: 'Network error.');
    }
  }

  /// Resolve a prediction's [placeId] to a full [Place] with real coordinates.
  static Future<Place?> details(String placeId, {String? sessionToken}) async {
    if (placeId.isEmpty || !EvcSupabase.isReady) return null;

    try {
      final res = await EvcSupabase.client.functions.invoke('maps-proxy', body: {
        'op': 'details',
        'placeId': placeId,
        'sessionToken': sessionToken,
      });
      final data = res.data as Map<String, dynamic>?;
      final gStatus = (data?['status'] as num?)?.toInt() ?? 0;
      final body = data?['body'] as Map<String, dynamic>?;
      if (gStatus != 200 || body == null) return null;
      final loc = body['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      return Place(
        name: (body['displayName'] as Map<String, dynamic>?)?['text']
                as String? ??
            'Destination',
        address: body['formattedAddress'] as String? ?? '',
        kind: PlaceKind.search,
        lat: (loc['latitude'] as num).toDouble(),
        lng: (loc['longitude'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
