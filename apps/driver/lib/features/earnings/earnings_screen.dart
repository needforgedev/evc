import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/driver_account.dart';
import '../../state/driver_data.dart';

/// Earnings dashboard — real period totals from `driver_earnings_view`.
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  int _period = 0;

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(driverEarningsProvider);
    final driver = ref.watch(currentDriverProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        top: false,
        child: earningsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load earnings.\n$e')),
          data: (summaries) {
            final s = summaries[_period];
            return ListView(
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
                        colors: [EvcColors.primaryDark, EvcColors.primary]),
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
                    _stat('${driver?.acceptanceRate.toStringAsFixed(0) ?? '—'}%',
                        'Acceptance', Icons.task_alt),
                    const SizedBox(width: 12),
                    _stat(driver?.rating.toStringAsFixed(2) ?? '—', 'Rating',
                        Icons.star_border),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: s.totalAed > 0
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Cashing out to your bank…')),
                          )
                      : null,
                  icon: const Icon(Icons.bolt),
                  label: Text('Cash out AED ${s.totalAed.toStringAsFixed(2)}'),
                ),
                const SizedBox(height: 24),
                if (s.trips == 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: EvcColors.mist,
                      borderRadius: BorderRadius.circular(EvcRadius.md),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.electric_car,
                            color: EvcColors.slate, size: 32),
                        SizedBox(height: 10),
                        Text('No completed trips yet',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Go online and complete trips to start earning.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: EvcColors.slate, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            );
          },
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
