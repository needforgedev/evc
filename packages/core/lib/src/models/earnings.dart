/// One completed trip in the driver's earnings list.
class EarningEntry {
  const EarningEntry({
    required this.timeLabel,
    required this.routeLabel,
    required this.amountAed,
    required this.tipAed,
  });

  final String timeLabel;
  final String routeLabel;
  final double amountAed;
  final double tipAed;

  double get totalAed => amountAed + tipAed;
}

/// A driver's stats for a period (today / week / month).
class EarningsSummary {
  const EarningsSummary({
    required this.label,
    required this.totalAed,
    required this.trips,
    required this.onlineHours,
    required this.tipsAed,
    required this.entries,
  });

  final String label;
  final double totalAed;
  final int trips;
  final double onlineHours;
  final double tipsAed;
  final List<EarningEntry> entries;
}