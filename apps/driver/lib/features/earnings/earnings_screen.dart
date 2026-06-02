import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/mock_data.dart';

/// Earnings dashboard — period totals, stats, per-trip breakdown, cash out.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _period = 0;

  List<EarningsSummary> get _summaries =>
      [DriverMock.today, DriverMock.week, DriverMock.month];

  @override
  Widget build(BuildContext context) {
    final s = _summaries[_period];
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Today')),
                ButtonSegment(value: 1, label: Text('Week')),
                ButtonSegment(value: 2, label: Text('Month')),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _period = v.first),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EvcColors.primaryDark, EvcColors.primary],
                ),
                borderRadius: BorderRadius.circular(EvcRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.label} earnings',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text('AED ${s.totalAed.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Includes AED ${s.tipsAed.toStringAsFixed(0)} in tips',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('${s.trips}', 'Trips', Icons.route_outlined),
                const SizedBox(width: 12),
                _stat('${s.onlineHours}h', 'Online', Icons.timer_outlined),
                const SizedBox(width: 12),
                _stat('94%', 'Acceptance', Icons.task_alt),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cashing out to your bank…')),
              ),
              icon: const Icon(Icons.bolt),
              label: Text('Cash out AED ${s.totalAed.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 24),
            if (s.entries.isNotEmpty) ...[
              const Text('Trip breakdown',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              for (final e in s.entries) _EntryRow(entry: e),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Per-trip breakdown is shown for Today.',
                    style: TextStyle(color: EvcColors.slate)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EvcColors.surface,
          borderRadius: BorderRadius.circular(EvcRadius.md),
          border: Border.all(color: EvcColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: EvcColors.ink, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label,
                style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final EarningEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: EvcColors.mist,
          child: Icon(Icons.electric_car, color: EvcColors.ink),
        ),
        title: Text(entry.routeLabel,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(entry.timeLabel +
            (entry.tipAed > 0
                ? '  ·  +AED ${entry.tipAed.toStringAsFixed(0)} tip'
                : '')),
        trailing: Text('AED ${entry.totalAed.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}