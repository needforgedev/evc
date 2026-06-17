import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'evc_location.dart';

/// Named marker colours, so app code never imports `BitmapDescriptor`.
abstract final class EvcMarkerHue {
  static const double green = BitmapDescriptor.hueGreen;
  static const double red = BitmapDescriptor.hueRed;
  static const double azure = BitmapDescriptor.hueAzure;
  static const double orange = BitmapDescriptor.hueOrange;
}

/// A map marker, described in app terms (no google_maps_flutter import needed
/// by callers).
class EvcMarker {
  const EvcMarker({
    required this.id,
    required this.position,
    this.title,
    this.hue = BitmapDescriptor.hueGreen,
  });

  final String id;
  final LatLng position;
  final String? title;

  /// Pin colour (a `BitmapDescriptor.hue*` constant).
  final double hue;
}

/// The real Google map, wrapped so app code talks to one EVC type instead of
/// the raw plugin. Centers on Dubai by default (see [kDubaiCenter]).
///
/// Pass [route] to draw a polyline (pickup → destination); when set, the camera
/// fits the whole route instead of centering on [center].
///
/// Swapping the underlying provider (MapLibre/OSM) later means changing only
/// this file — the apps keep using [EvcGoogleMap] / [EvcMarker].
class EvcGoogleMap extends StatefulWidget {
  const EvcGoogleMap({
    super.key,
    this.center = kDubaiCenter,
    this.zoom = 13,
    this.markers = const [],
    this.route = const [],
    this.showMyLocationButton = false,
  });

  /// Initial camera target; also re-centered on whenever it changes (ignored
  /// when [route] is non-empty — the camera fits the route then).
  final LatLng center;
  final double zoom;
  final List<EvcMarker> markers;

  /// Polyline points to draw (pickup → destination). Empty hides the route.
  final List<LatLng> route;

  /// Shows the native "recenter on me" button. Off by default during dev, since
  /// the device's real position is outside the UAE (see [EvcLocation]).
  final bool showMyLocationButton;

  @override
  State<EvcGoogleMap> createState() => _EvcGoogleMapState();
}

class _EvcGoogleMapState extends State<EvcGoogleMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant EvcGoogleMap old) {
    super.didUpdateWidget(old);
    if (widget.route.isNotEmpty) {
      // Only refit when the route itself changes (not on every car-marker tick).
      if (old.route.length != widget.route.length ||
          (old.route.isNotEmpty && old.route.first != widget.route.first)) {
        _fitRoute();
      }
    } else if (old.center != widget.center) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.center, widget.zoom),
      );
    }
  }

  void _fitRoute() {
    final c = _controller;
    if (c == null || widget.route.isEmpty) return;
    var minLat = widget.route.first.latitude, maxLat = minLat;
    var minLng = widget.route.first.longitude, maxLng = minLng;
    for (final p in widget.route) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition:
          CameraPosition(target: widget.center, zoom: widget.zoom),
      onMapCreated: (c) {
        _controller = c;
        if (widget.route.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
        }
      },
      myLocationButtonEnabled: widget.showMyLocationButton,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      markers: {
        for (final m in widget.markers)
          Marker(
            markerId: MarkerId(m.id),
            position: m.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(m.hue),
            infoWindow:
                m.title == null ? InfoWindow.noText : InfoWindow(title: m.title),
          ),
      },
      polylines: {
        if (widget.route.length >= 2)
          Polyline(
            polylineId: const PolylineId('route'),
            points: widget.route,
            color: const Color(0xFF12B76A),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
      },
    );
  }
}
