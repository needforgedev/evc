/// EVC realtime — trip-state streaming client.
///
/// Wraps Supabase Realtime / websockets so all three apps observe the same live
/// trip and driver-location updates. Channel + stream APIs land here next.
library;

/// Marker constant proving the package is wired into the workspace.
const String evcRealtimeTransport = 'supabase_realtime';