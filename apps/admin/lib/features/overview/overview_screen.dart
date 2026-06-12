import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../../state/admin_data.dart';
import '../../state/admin_session.dart';
import '../drivers/drivers_screen.dart';

/// Ops overview — real KPIs + pending approvals.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(adminDriversProvider).value ?? const [];
    final trips = ref.watch(adminTripsProvider).value ?? const [];
    final admin = ref.watch(currentAdminProvider).value;

    final pending =
        drivers.where((d) => d.status == DriverAccountStatus.pending).toList();
    final activeDrivers =
        drivers.where((d) => d.status == DriverAccountStatus.active).length;
    final ongoing =
        trips.where((t) => t.status == AdminTripStatus.ongoing).length;
    final completed =
        trips.where((t) => t.status == AdminTripStatus.completed).toList();
    final revenue =
        completed.fold<double>(0, (s, t) => s + t.fareAed);
    final tr = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.overview),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(adminDriversProvider);
              ref.invalidate(adminTripsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: EvcColors.ink,
              child: Text(admin?.initials ?? 'OP',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminDriversProvider);
            ref.invalidate(adminTripsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  _kpi('$ongoing', tr.activeTrips, Icons.alt_route,
                      EvcColors.primary),
                  const SizedBox(width: 12),
                  _kpi('$activeDrivers', tr.activeDrivers, Icons.local_taxi,
                      EvcColors.ink),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _kpi('${completed.length}', tr.completedTrips,
                      Icons.check_circle_outline, EvcColors.ink),
                  const SizedBox(width: 12),
                  _kpi('AED ${revenue.toStringAsFixed(0)}', tr.revenue,
                      Icons.payments_outlined, EvcColors.primaryDark,
                      highlight: true),
                ],
              ),
              const SizedBox(height: 16),
              if (pending.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(EvcRadius.md),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DriversScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EvcColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(EvcRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.how_to_reg, color: Color(0xFFB78000)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr.awaitingApproval(pending.length),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(tr.network,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              _row(Icons.group_outlined, tr.totalDrivers, '${drivers.length}'),
              _row(Icons.route_outlined, tr.totalTrips, '${trips.length}'),
              _row(Icons.hourglass_bottom, tr.pendingApprovals,
                  '${pending.length}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpi(String value, String label, IconData icon, Color color,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight
              ? EvcColors.primary.withValues(alpha: 0.10)
              : EvcColors.surface,
          borderRadius: BorderRadius.circular(EvcRadius.md),
          border: Border.all(
              color: highlight ? Colors.transparent : EvcColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: EvcColors.slate, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: EvcColors.ink),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
