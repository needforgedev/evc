import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/driver_status_controller.dart';
import '../../state/job_controller.dart';
import '../trip/active_trip_screen.dart';
import 'widgets/ride_request_sheet.dart';

/// Driver home — map, online/offline control, and incoming requests.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _sheetOpen = false;

  void _goOnline() {
    ref.read(driverStatusProvider.notifier).goOnline();
    ref.read(jobControllerProvider.notifier).lookForRide();
  }

  void _goOffline() {
    ref.read(driverStatusProvider.notifier).goOffline();
    ref.read(jobControllerProvider.notifier).clear();
  }

  Future<void> _presentOffer() async {
    final request = ref.read(jobControllerProvider).request;
    if (request == null) return;
    _sheetOpen = true;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => RideRequestSheet(request: request),
    );
    _sheetOpen = false;
    if (!mounted) return;

    final job = ref.read(jobControllerProvider.notifier);
    if (accepted == true) {
      job.accept();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ActiveTripScreen()),
      );
    } else {
      job.decline();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(jobControllerProvider, (prev, next) {
      if (next.stage == JobStage.offered && !_sheetOpen) _presentOffer();
    });

    final driver = ref.watch(driverStatusProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: PlaceholderMap(pickup: DriverMock.driverLocation),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _StatusPill(status: driver.status),
                  const Spacer(),
                  _BatteryChip(
                      percent: driver.batteryPercent, rangeKm: driver.rangeKm),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _HomePanel(
              driver: driver,
              onGoOnline: _goOnline,
              onGoOffline: _goOffline,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final DriverStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DriverStatus.offline => ('Offline', EvcColors.slate),
      DriverStatus.online => ('Online', EvcColors.primary),
      DriverStatus.charging => ('Charging', EvcColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EvcRadius.lg),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BatteryChip extends StatelessWidget {
  const _BatteryChip({required this.percent, required this.rangeKm});
  final int percent;
  final int rangeKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EvcRadius.lg),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.battery_charging_full,
              color: EvcColors.primaryDark, size: 18),
          const SizedBox(width: 6),
          Text('$percent% · $rangeKm km',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.driver,
    required this.onGoOnline,
    required this.onGoOffline,
  });

  final DriverState driver;
  final VoidCallback onGoOnline;
  final VoidCallback onGoOffline;

  @override
  Widget build(BuildContext context) {
    final online = driver.isOnline;
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
              // Today's earnings snapshot.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EvcColors.mist,
                  borderRadius: BorderRadius.circular(EvcRadius.md),
                ),
                child: Row(
                  children: [
                    _miniStat('AED ${DriverMock.today.totalAed.toStringAsFixed(0)}',
                        'Earned today'),
                    _divider(),
                    _miniStat('${DriverMock.today.trips}', 'Trips'),
                    _divider(),
                    _miniStat('${DriverMock.today.onlineHours}h', 'Online'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (online)
                Row(
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: EvcColors.primary),
                    ),
                    SizedBox(width: 12),
                    Text('Looking for trips nearby…',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              if (online) const SizedBox(height: 14),
              FilledButton(
                style: online
                    ? FilledButton.styleFrom(
                        backgroundColor: EvcColors.ink,
                        foregroundColor: Colors.white,
                      )
                    : null,
                onPressed: online ? onGoOffline : onGoOnline,
                child: Text(online ? 'Go offline' : 'Go online'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: EvcColors.line,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}