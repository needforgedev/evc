import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/admin_mock.dart';
import '../../state/admin_controller.dart';
import '../drivers/drivers_screen.dart';

/// Ops overview — KPIs, pending approvals, demand and live alerts.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminControllerProvider);
    final onlineDrivers = AdminMock.fleet
        .where((v) => v.status == VehicleStatus.active)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none)),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: EvcColors.ink,
              child: Text('OP',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                _kpi('${admin.ongoing.length}', 'Active trips',
                    Icons.alt_route, EvcColors.primary),
                const SizedBox(width: 12),
                _kpi('$onlineDrivers', 'Online drivers',
                    Icons.local_taxi, EvcColors.ink),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kpi('AED 12.4k', 'Revenue today',
                    Icons.payments_outlined, EvcColors.ink),
                const SizedBox(width: 12),
                _kpi('184 kg', 'CO₂ saved today',
                    Icons.eco_rounded, EvcColors.primaryDark,
                    highlight: true),
              ],
            ),
            const SizedBox(height: 16),
            // Pending approvals.
            if (admin.pending.isNotEmpty)
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
                      const Icon(Icons.how_to_reg,
                          color: Color(0xFFB78000)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${admin.pending.length} driver${admin.pending.length == 1 ? '' : 's'} awaiting approval',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text('Demand · today',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            const _DemandChart(),
            const SizedBox(height: 24),
            const Text('Live alerts',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            _alert(Icons.battery_alert, EvcColors.warning,
                'BYD Atto 3 (B 11920) low battery — 24%', 'Charging now'),
            _alert(Icons.build_circle_outlined, EvcColors.danger,
                'Ioniq 5 (A 30188) flagged for maintenance', 'Out of service'),
            _alert(Icons.shield_outlined, EvcColors.danger,
                'Safety report on trip T-90388', 'Open ticket'),
          ],
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

  Widget _alert(IconData icon, Color color, String text, String tag) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14))),
            Text(tag,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DemandChart extends StatelessWidget {
  const _DemandChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        border: Border.all(color: EvcColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final b in AdminMock.demand)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 88 * b.value,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: b.value > 0.8
                          ? EvcColors.primary
                          : EvcColors.primary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(b.hour,
                      style: const TextStyle(
                          fontSize: 10, color: EvcColors.slate)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}