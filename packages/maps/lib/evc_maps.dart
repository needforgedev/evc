/// EVC maps + location abstraction.
///
/// All map/location use in the apps goes through this package so the underlying
/// provider (Google Maps now) can be swapped for MapLibre/OSM later without
/// touching app code. For the mock it ships a stylised [PlaceholderMap] shared
/// by the Rider and Driver apps.
library;

export 'src/placeholder_map.dart';

/// Marker constant identifying the current map provider.
const String evcMapsProvider = 'google_maps';