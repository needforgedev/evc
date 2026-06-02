import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/driver_status_controller.dart';
import '../../state/job_controller.dart';

/// Shown after a completed trip — driver earnings + rate the rider.
class TripSummaryScreen extends ConsumerStatefulWidget {
  const TripSummaryScreen({super.key});

  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  int _rating = 5;

  void _done() {
    final online = ref.read(driverStatusProvider).isOnline;
    ref.read(jobControllerProvider.notifier).clear();
    // Stay in the loop: surface the next request if still online.
    if (online) ref.read(jobControllerProvider.notifier).lookForRide();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.read(jobControllerProvider).request;
    final fare = request?.fareAed ?? 0;
    const tip = 5.0;
    final subtotal = fare + tip;
    final fee = subtotal * 0.15;
    final earned = subtotal - fee;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: EvcColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: EvcColors.primaryDark, size: 36),
                        ),
                        const SizedBox(height: 12),
                        const Text('You earned',
                            style: TextStyle(color: EvcColors.slate)),
                        Text('AED ${earned.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 38, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _row('Trip fare', fare),
                          _row('Tip', tip),
                          const Divider(height: 22),
                          _row('Subtotal', subtotal),
                          _row('EVC service fee (15%)', -fee),
                          const Divider(height: 22),
                          _row('Your earnings', earned, bold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Rate your rider',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final on = i < _rating;
                      return IconButton(
                        iconSize: 38,
                        onPressed: () => setState(() => _rating = i + 1),
                        icon: Icon(
                            on
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: on ? EvcColors.warning : EvcColors.line),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: FilledButton(onPressed: _done, child: const Text('Done')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double aed, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 17 : 15,
      color: aed < 0 ? EvcColors.slate : EvcColors.ink,
    );
    final amount = aed < 0
        ? '- AED ${aed.abs().toStringAsFixed(2)}'
        : 'AED ${aed.toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(amount, style: style)],
      ),
    );
  }
}