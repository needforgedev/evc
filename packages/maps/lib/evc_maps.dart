/// EVC maps + location abstraction.
///
/// All map/location use in the apps goes through this package so the underlying
/// provider (Google Maps now) can be swapped for MapLibre/OSM later without
/// touching app code. For the mock it ships a stylised [PlaceholderMap] shared
/// by the Rider and Driver apps.
library;

export 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

export 'src/placeholder_map.dart';
export 'src/evc_google_map.dart';
export 'src/evc_location.dart';
export 'src/evc_directions.dart';

/// Marker constant identifying the current map provider.
const String evcMapsProvider = 'google_maps';