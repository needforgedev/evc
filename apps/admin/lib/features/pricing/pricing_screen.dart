import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/admin_mock.dart';

/// Pricing & promotions — base rates, surge by zone, promo codes.
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing & promos')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text('Base rates',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                _rate('AED ${AdminMock.baseFare.toStringAsFixed(2)}', 'Base'),
                const SizedBox(width: 12),
                _rate('AED ${AdminMock.perKm.toStringAsFixed(2)}', 'per km'),
                const SizedBox(width: 12),
                _rate('AED ${AdminMock.perMin.toStringAsFixed(2)}', 'per min'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Surge by zone',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final z in AdminMock.surges)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.place_outlined,
                      color: EvcColors.ink),
                  title: Text(z.zone,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: z.multiplier > 1
                          ? EvcColors.warning.withValues(alpha: 0.14)
                          : EvcColors.mist,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${z.multiplier}×',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: z.multiplier > 1
                                ? const Color(0xFFB78000)
                                : EvcColors.slate)),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Promo codes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final p in AdminMock.promos)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.local_offer_outlined,
                      color: EvcColors.ink),
                  title: Text(p.code,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, letterSpacing: 1)),
                  subtitle: Text(
                      '${p.description} · ${p.redemptions} redemptions'),
                  trailing: Switch(value: p.active, onChanged: (_) {}),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('New promo code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rate(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EvcColors.surface,
          borderRadius: BorderRadius.circular(EvcRadius.md),
          border: Border.all(color: EvcColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}