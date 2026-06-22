// Loads the Google Maps JavaScript API (web only) so `google_maps_flutter`
// works in the browser. On mobile this is a no-op (the native SDK key is used).
//
// The key comes from the `--dart-define`d `EvcConfig.gmapsApiKey`, so it's not
// committed in `web/index.html`. (On web a Maps key is inherently visible in
// network traffic regardless — protect it with HTTP referrer restrictions.)
export 'maps_loader_stub.dart'
    if (dart.library.js_interop) 'maps_loader_web.dart';
