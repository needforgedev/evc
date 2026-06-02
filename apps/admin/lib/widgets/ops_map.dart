import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../mock/admin_mock.dart';

/// The live operations map: the shared [PlaceholderMap] base with demand
/// hotspots and fleet-vehicle markers layered on top.
class OpsMap extends StatelessWidget {
  const OpsMap({
    super.key,
    required this.fleet,
    this.hotspots = const [],
  });

  final List<FleetVehicle> fleet;
  final List<Hotspot> hotspots;

  static Color statusColor(VehicleStatus s) => switch (s) {
        VehicleStatus.active => EvcColors.primary,
        VehicleStatus.charging => EvcColors.warning,
        VehicleStatus.maintenance => EvcColors.danger,
        VehicleStatus.offline => EvcColors.slate,
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: [
            const Positioned.fill(child: PlaceholderMap()),
            for (final h in hotspots)
              Positioned(
                left: h.mapX * c.maxWidth - 60 * h.intensity,
                top: h.mapY * c.maxHeight - 60 * h.intensity,
                child: Container(
                  width: 120 * h.intensity,
                  height: 120 * h.intensity,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        EvcColors.danger.withValues(alpha: 0.35 * h.intensity),
                        EvcColors.danger.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            for (final v in fleet)
              Positioned(
                left: v.mapX * c.maxWidth - 17,
                top: v.mapY * c.maxHeight - 17,
                child: _VehicleMarker(color: statusColor(v.status)),
              ),
          ],
        );
      },
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.local_taxi, color: Colors.white, size: 17),
    );
  }
}