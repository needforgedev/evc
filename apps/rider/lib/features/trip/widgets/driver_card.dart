import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

/// Bottom panel shown once a driver is matched — identity, vehicle, the
/// battery-aware assurance, trip PIN, and contact/safety actions.
class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.driver,
    required this.stage,
    required this.onSkip,
    required this.onCancel,
  });

  final DriverProfile driver;
  final TripStage stage;
  final VoidCallback onSkip;
  final VoidCallback onCancel;

  bool get _inProgress => stage == TripStage.inProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EvcColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: driver.avatarColor,
                    child: Text(driver.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 15, color: EvcColors.warning),
                            const SizedBox(width: 4),
                            Text('${driver.rating}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text('  ·  ${driver.totalTrips} trips',
                                style: const TextStyle(
                                    color: EvcColors.slate, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _PinBox(),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EvcColors.mist,
                  borderRadius: BorderRadius.circular(EvcRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_filled,
                        color: EvcColors.ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${driver.vehicleColor} ${driver.vehicleModel}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: EvcColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: EvcColors.line),
                      ),
                      child: Text(driver.plate,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Battery-aware assurance — the EV brand promise.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: EvcColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(EvcRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.battery_charging_full,
                        color: EvcColors.primaryDark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${driver.batteryPercent}% battery — enough range to finish your trip',
                        style: const TextStyle(
                            color: EvcColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.verified,
                        color: EvcColors.primaryDark, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!_inProgress)
                Row(
                  children: [
                    _action(Icons.call, 'Call'),
                    const SizedBox(width: 10),
                    _action(Icons.chat_bubble_outline, 'Message'),
                    const SizedBox(width: 10),
                    _action(Icons.ios_share, 'Share'),
                    const SizedBox(width: 10),
                    _action(Icons.shield_outlined, 'Safety'),
                  ],
                )
              else
                Row(
                  children: [
                    _action(Icons.shield_outlined, 'Safety'),
                    const SizedBox(width: 10),
                    _action(Icons.ios_share, 'Share trip'),
                    const SizedBox(width: 10),
                    _action(Icons.report_gmailerrorred_outlined, 'SOS',
                        danger: true),
                  ],
                ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onSkip,
                child: Text(_inProgress
                    ? 'Complete trip  ›  (demo)'
                    : stage == TripStage.arrived
                        ? 'Start trip  ›  (demo)'
                        : 'Skip to arrival  ›  (demo)'),
              ),
              if (!_inProgress)
                Center(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: EvcColors.danger),
                    child: const Text('Cancel ride'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, {bool danger = false}) {
    final color = danger ? EvcColors.danger : EvcColors.ink;
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: danger
                  ? EvcColors.danger.withValues(alpha: 0.08)
                  : EvcColors.mist,
              borderRadius: BorderRadius.circular(EvcRadius.sm),
              border: Border.all(
                  color: danger
                      ? EvcColors.danger.withValues(alpha: 0.4)
                      : EvcColors.line),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Trip PIN',
            style: TextStyle(color: EvcColors.slate, fontSize: 11)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: EvcColors.ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('4827',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 3)),
        ),
      ],
    );
  }
}