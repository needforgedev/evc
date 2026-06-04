import 'package:flutter/widgets.dart';

/// What kind of saved/searched place this is — drives the leading icon.
enum PlaceKind { home, work, recent, search, pin }

/// A pickup or destination location.
///
/// [lat]/[lng] are real coordinates (used for fares/dispatch). [mapX]/[mapY]
/// are normalised 0..1 coordinates for the stylised placeholder map.
@immutable
class Place {
  const Place({
    required this.name,
    required this.address,
    this.kind = PlaceKind.pin,
    this.lat = 0,
    this.lng = 0,
    this.mapX = 0.5,
    this.mapY = 0.5,
  });

  final String name;
  final String address;
  final PlaceKind kind;
  final double lat;
  final double lng;
  final double mapX;
  final double mapY;
}