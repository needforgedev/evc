import 'package:flutter/widgets.dart';

/// What kind of saved/searched place this is — drives the leading icon.
enum PlaceKind { home, work, recent, search, pin }

/// A pickup or destination location.
///
/// [mapX]/[mapY] are normalised 0..1 coordinates used only to position the pin
/// on the stylised placeholder map (no real geocoding in the mock).
@immutable
class Place {
  const Place({
    required this.name,
    required this.address,
    this.kind = PlaceKind.pin,
    this.mapX = 0.5,
    this.mapY = 0.5,
  });

  final String name;
  final String address;
  final PlaceKind kind;
  final double mapX;
  final double mapY;
}