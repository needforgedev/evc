import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('google')
external JSAny? get _google;

/// True once the Maps JS API has populated `window.google.maps`.
bool _ready() {
  final g = _google;
  if (g.isUndefinedOrNull) return false;
  return (g as JSObject).has('maps');
}

bool _started = false;

/// Inject the Google Maps JS API script and wait until it's ready.
Future<void> loadGoogleMapsJs(String key) async {
  if (key.isEmpty || _ready()) return;

  if (!_started) {
    _started = true;
    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://maps.googleapis.com/maps/api/js?key=$key';
    script.async = true;
    web.document.head!.appendChild(script);
  }

  // Poll until the API is available (max ~10s).
  for (var i = 0; i < 100; i++) {
    if (_ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
