import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/booking_controller.dart';
import '../rating/rating_screen.dart';

/// Trip-complete summary + VAT-compliant fare breakdown.
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);
    final tier = booking.effectiveTier;

    final fare = tier.fareAed;
    final base = fare * 0.40;
    final distance = fare * 0.45;
    final time = fare * 0.15;
    final vat = fare * 0.05;
    final total = fare + vat;

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
                        const SizedBox(height: 14),
                        Text('Trip completed',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${booking.pickup.name} → ${booking.destination?.name ?? ''}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: EvcColors.slate)),
                        const SizedBox(height: 12),
                        Co2Badge(kg: tier.co2SavedKg),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _row('Base fare', base),
                          _row('Distance (14.2 km)', distance),
                          _row('Time (18 min)', time),
                          const Divider(height: 22),
                          _row('Subtotal', fare),
                          _row('VAT (5%)', vat),
                          const Divider(height: 22),
                          _row('Total', total, bold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: ListTile(
                      leading: Icon(booking.payment.icon, color: EvcColors.ink),
                      title: Text(booking.payment.label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Charged ${booking.payment.detail}'),
                      trailing: const Icon(Icons.receipt_long_outlined,
                          color: EvcColors.slate),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RatingScreen()),
                ),
                child: const Text('Rate your trip'),
              ),
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
      color: EvcColors.ink,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          Text('AED ${aed.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}