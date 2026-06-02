import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../mock/admin_mock.dart';

/// Analytics — sustainability, demand, charging utilization, retention.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            // CO2 highlight — sustainability reporting.
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
                children: const [
                  Row(
                    children: [
                      Icon(Icons.eco_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text('CO₂ saved · this month',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('48.2 tonnes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800)),
                  Text('vs. an equivalent petrol fleet',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('24,118', 'Trips', Icons.alt_route),
                const SizedBox(width: 12),
                _stat('4.91', 'Avg rating', Icons.star_border),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('72%', 'Charger utilization', Icons.ev_station),
                const SizedBox(width: 12),
                _stat('68%', '30-day retention', Icons.repeat),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Demand by hour',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              height: 150,
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
                            height: 96 * b.value,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
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
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EvcColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(EvcRadius.md),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFFB78000)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Supply gap forecast: +14 drivers needed in Downtown 6–9pm.',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
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
            Icon(icon, color: EvcColors.ink, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label,
                style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}