import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

/// Finance — revenue, commission, driver payouts and VAT.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [EvcColors.ink, Color(0xFF14342A)],
                ),
                borderRadius: BorderRadius.circular(EvcRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gross revenue · this month',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  const Text('AED 612,480',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.trending_up,
                          color: EvcColors.primary, size: 18),
                      SizedBox(width: 4),
                      Text('+18% vs last month',
                          style: TextStyle(color: EvcColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Gross revenue', 'AED 612,480'),
                    _row('EVC commission (15%)', 'AED 91,872'),
                    _row('Driver payouts', 'AED 520,608'),
                    const Divider(height: 22),
                    _row('VAT collected (5%)', 'AED 29,166'),
                    _row('Net to remit (FTA)', 'AED 29,166'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule, color: EvcColors.ink),
                title: const Text('Next driver payout',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Weekly · runs every Monday'),
                trailing: const Text('AED 118,240',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined,
                    color: EvcColors.primary),
                title: const Text('Reconciliation',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Cash vs card settled'),
                trailing: const Text('Balanced',
                    style: TextStyle(
                        color: EvcColors.primaryDark,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}