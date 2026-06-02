enum AdminTripStatus { ongoing, completed, canceled }

/// A trip as monitored by Admin. Mirrors the single `trips` record that Rider
/// creates and Driver fulfils. [mapX]/[mapY] are the live vehicle position.
class AdminTrip {
  const AdminTrip({
    required this.id,
    required this.riderName,
    required this.driverName,
    required this.fromName,
    required this.toName,
    required this.tierName,
    required this.fareAed,
    required this.status,
    required this.stageLabel,
    required this.etaMinutes,
    required this.mapX,
    required this.mapY,
  });

  final String id;
  final String riderName;
  final String driverName;
  final String fromName;
  final String toName;
  final String tierName;
  final double fareAed;
  final AdminTripStatus status;

  /// Free-text live stage, e.g. "En route to pickup".
  final String stageLabel;
  final int etaMinutes;
  final double mapX;
  final double mapY;

  AdminTrip copyWith({AdminTripStatus? status, String? stageLabel}) => AdminTrip(
        id: id,
        riderName: riderName,
        driverName: driverName,
        fromName: fromName,
        toName: toName,
        tierName: tierName,
        fareAed: fareAed,
        status: status ?? this.status,
        stageLabel: stageLabel ?? this.stageLabel,
        etaMinutes: etaMinutes,
        mapX: mapX,
        mapY: mapY,
      );
}