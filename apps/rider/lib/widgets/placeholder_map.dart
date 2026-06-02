import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

/// A stylised, fake map used throughout the Rider mock — no real map provider
/// or API key. Draws roads, parks and water, an optional pickup→destination
/// route, and an optional car travelling along that route.
class PlaceholderMap extends StatelessWidget {
  const PlaceholderMap({
    super.key,
    this.pickup,
    this.destination,
    this.carProgress,
    this.showRoute = false,
  });

  final Place? pickup;
  final Place? destination;

  /// 0..1 position of the car along the route. Null hides the car.
  final double? carProgress;
  final bool showRoute;

  Offset _px(Place p, Size s) => Offset(p.mapX * s.width, p.mapY * s.height);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final pickupPx = pickup == null ? null : _px(pickup!, size);
        final destPx = destination == null ? null : _px(destination!, size);

        Offset? control;
        if (pickupPx != null && destPx != null) {
          control = _controlPoint(pickupPx, destPx);
        }

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _MapPainter(
                  route: showRoute && pickupPx != null && destPx != null
                      ? (pickupPx, control!, destPx)
                      : null,
                ),
              ),
              if (pickupPx != null)
                _pin(pickupPx, const _PickupDot()),
              if (destPx != null)
                _pin(destPx, const Icon(Icons.location_on,
                    color: EvcColors.ink, size: 38)),
              if (carProgress != null && pickupPx != null && destPx != null)
                _pin(
                  _quadBezier(pickupPx, control!, destPx,
                      carProgress!.clamp(0.0, 1.0)),
                  const _CarMarker(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _pin(Offset at, Widget child) {
    return Positioned(
      left: at.dx - 22,
      top: at.dy - 38,
      width: 44,
      height: 44,
      child: Align(alignment: Alignment.bottomCenter, child: child),
    );
  }
}

Offset _controlPoint(Offset a, Offset b) {
  final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  final dir = b - a;
  // Perpendicular offset gives the route a gentle, road-like bow.
  final perp = Offset(-dir.dy, dir.dx);
  final double len = perp.distance == 0 ? 1.0 : perp.distance;
  return mid + perp / len * 36;
}

Offset _quadBezier(Offset a, Offset c, Offset b, double t) {
  final u = 1 - t;
  return a * (u * u) + c * (2 * u * t) + b * (t * t);
}

class _PickupDot extends StatelessWidget {
  const _PickupDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: EvcColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: EvcColors.primary.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _CarMarker extends StatelessWidget {
  const _CarMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: EvcColors.ink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.navigation_rounded,
          color: EvcColors.primary, size: 18),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({this.route});

  /// (start, controlPoint, end) of the route bezier, in pixels.
  final (Offset, Offset, Offset)? route;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE9EFEA);
    canvas.drawRect(Offset.zero & size, bg);

    // Water (a corner of the Gulf / marina).
    final water = Paint()..color = const Color(0xFFCFE3F0);
    final waterPath = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.18, size.height * 0.70,
          size.width * 0.22, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(waterPath, water);

    // Parks / green blocks.
    final park = Paint()..color = const Color(0xFFD4E8D2);
    for (final r in const [
      Rect.fromLTWH(0.66, 0.66, 0.22, 0.18),
      Rect.fromLTWH(0.08, 0.10, 0.16, 0.14),
      Rect.fromLTWH(0.78, 0.40, 0.18, 0.16),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left * size.width, r.top * size.height,
              r.width * size.width, r.height * size.height),
          const Radius.circular(10),
        ),
        park,
      );
    }

    // Road grid — thick casings then white road fills.
    final roadCasing = Paint()
      ..color = const Color(0xFFDBE3DD)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final verticals = [0.22, 0.46, 0.66, 0.84];
    final horizontals = [0.24, 0.44, 0.62, 0.82];
    for (final paint in [roadCasing, road]) {
      for (final x in verticals) {
        canvas.drawLine(Offset(x * size.width, size.height * 0.04),
            Offset(x * size.width, size.height * 0.96), paint);
      }
      for (final y in horizontals) {
        canvas.drawLine(Offset(size.width * 0.04, y * size.height),
            Offset(size.width * 0.96, y * size.height), paint);
      }
    }

    // Route polyline (white casing + EV-green line).
    if (route != null) {
      final (a, c, b) = route!;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = EvcColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.route != route;
}