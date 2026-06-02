/// EVC maps + location abstraction.
///
/// All map/location use in the apps goes through this package so the underlying
/// provider (Google Maps now) can be swapped for MapLibre/OSM later without
/// touching app code. Real interfaces (geocoding, routing, ETA) land here next.
library;

/// Marker constant proving the package is wired into the workspace.
const String evcMapsProvider = 'google_maps';