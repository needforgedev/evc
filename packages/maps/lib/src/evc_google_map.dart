import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'evc_location.dart';

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
/// Swapping the underlying provider (MapLibre/OSM) later means changing only
/// this file — the apps keep using [EvcGoogleMap] / [EvcMarker].
class EvcGoogleMap extends StatefulWidget {
  const EvcGoogleMap({
    super.key,
    this.center = kDubaiCenter,
    this.zoom = 13,
    this.markers = const [],
    this.showMyLocationButton = false,
  });

  /// Initial camera target; also re-centered on whenever it changes.
  final LatLng center;
  final double zoom;
  final List<EvcMarker> markers;

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
    if (old.center != widget.center) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.center, widget.zoom),
      );
    }
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
      onMapCreated: (c) => _controller = c,
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
    );
  }
}
