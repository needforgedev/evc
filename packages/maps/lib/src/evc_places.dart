import 'dart:convert';

import 'package:evc_core/evc_core.dart';
import 'package:http/http.dart' as http;

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
/// (e.g. "Places API (New) has not been enabled…") so the UI can explain why
/// live search returned nothing instead of silently showing "No places found".
class EvcAutocompleteResult {
  const EvcAutocompleteResult(this.items, {this.error});
  final List<EvcPlacePrediction> items;
  final String? error;
}

/// Google **Places API (New)** wrapper: type-ahead suggestions + resolving a
/// pick to real coordinates. Restricted to the UAE and biased toward Dubai.
///
/// Uses the `places.googleapis.com/v1` endpoints with an `X-Goog-Api-Key`
/// header (the current API; the legacy `maps/api/place/*` endpoints are not
/// enableable on most newly-created keys).
///
/// Dev note: calls the web service directly with the dart-define key. For
/// production, proxy through a Supabase edge function so the key isn't shipped.
class EvcPlaces {
  const EvcPlaces._();

  static const double _biasLat = 25.2048;
  static const double _biasLng = 55.2708;

  static Future<EvcAutocompleteResult> autocomplete(
    String input, {
    String? sessionToken,
  }) async {
    final key = EvcConfig.gmapsApiKey;
    if (key.isEmpty) {
      return const EvcAutocompleteResult([],
          error: 'No Maps API key configured.');
    }
    if (input.trim().length < 2) return const EvcAutocompleteResult([]);

    final uri = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
    final body = jsonEncode({
      'input': input.trim(),
      'includedRegionCodes': ['ae'],
      'locationBias': {
        'circle': {
          'center': {'latitude': _biasLat, 'longitude': _biasLng},
          'radius': 50000.0,
        }
      },
      'sessionToken': ?sessionToken,
    });

    try {
      final res = await http
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': key,
              },
              body: body)
          .timeout(const Duration(seconds: 8));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        final msg =
            (json['error'] as Map<String, dynamic>?)?['message'] as String?;
        return EvcAutocompleteResult(const [],
            error: msg ?? 'Places error ${res.statusCode}');
      }
      final sugg = json['suggestions'] as List<dynamic>? ?? const [];
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
    final key = EvcConfig.gmapsApiKey;
    if (key.isEmpty || placeId.isEmpty) return null;

    final uri = Uri.https('places.googleapis.com', '/v1/places/$placeId', {
      'sessionToken': ?sessionToken,
    });

    try {
      final res = await http.get(uri, headers: {
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final loc = json['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      return Place(
        name: (json['displayName'] as Map<String, dynamic>?)?['text']
                as String? ??
            'Destination',
        address: json['formattedAddress'] as String? ?? '',
        kind: PlaceKind.search,
        lat: (loc['latitude'] as num).toDouble(),
        lng: (loc['longitude'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
