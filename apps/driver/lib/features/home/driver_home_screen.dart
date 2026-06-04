import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';
import '../../state/driver_account.dart';
import '../../state/driver_data.dart';
import '../../state/driver_job_provider.dart';
import '../trip/active_trip_screen.dart';

/// Driver home — map, real status/battery, and the online control (gated on
/// account approval). Presents incoming jobs (realtime) full-screen.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _busy = false;
  bool _jobOpen = false;

  Future<void> _toggleOnline(DriverAccount d) async {
    setState(() => _busy = true);
    try {
      await DriverActions.goOnline(!d.isOnline);
      ref.invalidate(currentDriverProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update status: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Present an incoming/active job full-screen (offer → drive → complete).
    ref.listen(driverJobProvider, (prev, next) {
      if (next.value != null && !_jobOpen) {
        _jobOpen = true;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ActiveTripScreen()))
            .then((_) {
          _jobOpen = false;
          ref.invalidate(driverEarningsProvider);
          ref.invalidate(currentDriverProvider);
        });
      }
    });

    final driverAsync = ref.watch(currentDriverProvider);

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
                  _StatusPill(driver: driverAsync.value),
                  const Spacer(),
                  if (driverAsync.value != null)
                    _BatteryChip(driver: driverAsync.value!),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: driverAsync.when(
              loading: () => const _PanelShell(
                  child: SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()))),
              error: (e, _) => _PanelShell(
                child: Text('Could not load your account.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: EvcColors.slate)),
              ),
              data: (d) => _HomePanel(
                driver: d,
                busy: _busy,
                onToggle: d == null ? null : () => _toggleOnline(d),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

(String, Color) _statusOf(DriverAccount? d) {
  if (d == null) return ('Offline', EvcColors.slate);
  if (d.isCharging) return ('Charging', EvcColors.warning);
  if (d.isOnline) return ('Online', EvcColors.primary);
  return ('Offline', EvcColors.slate);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.driver});
  final DriverAccount? driver;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusOf(driver);
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
  const _BatteryChip({required this.driver});
  final DriverAccount driver;

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
          Text('${driver.batteryPercent}% · ${driver.rangeKm} km',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});
  final Widget child;

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
          child: Padding(padding: const EdgeInsets.all(20), child: child)),
    );
  }
}

class _HomePanel extends ConsumerWidget {
  const _HomePanel({required this.driver, required this.busy, this.onToggle});

  final DriverAccount? driver;
  final bool busy;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(driverEarningsProvider);
    final today = earnings.value?.first;
    final online = driver?.isOnline ?? false;
    final pending = driver != null && !driver!.isActive;

    return _PanelShell(
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EvcColors.mist,
              borderRadius: BorderRadius.circular(EvcRadius.md),
            ),
            child: Row(
              children: [
                _miniStat('AED ${(today?.totalAed ?? 0).toStringAsFixed(0)}',
                    'Earned today'),
                _divider(),
                _miniStat('${today?.trips ?? 0}', 'Trips'),
                _divider(),
                _miniStat(driver?.rating.toStringAsFixed(2) ?? '—', 'Rating'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (pending)
            _pendingBanner()
          else if (online)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: EvcColors.primary)),
                  SizedBox(width: 12),
                  Text('Looking for trips nearby…',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          FilledButton(
            style: online
                ? FilledButton.styleFrom(
                    backgroundColor: EvcColors.ink, foregroundColor: Colors.white)
                : null,
            onPressed: (pending || busy) ? null : onToggle,
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(online ? 'Go offline' : 'Go online'),
          ),
        ],
      ),
    );
  }

  Widget _pendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EvcColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EvcRadius.sm),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_bottom, color: Color(0xFFB78000)),
          SizedBox(width: 10),
          Expanded(
            child: Text("Pending approval — you can't go online until ops verify your account.",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 8));
}
