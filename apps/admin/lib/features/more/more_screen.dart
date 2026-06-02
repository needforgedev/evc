import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../analytics/analytics_screen.dart';
import '../finance/finance_screen.dart';
import '../fleet/fleet_screen.dart';
import '../pricing/pricing_screen.dart';
import '../support/support_screen.dart';

/// Secondary ops sections.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Widget?)>[
      (Icons.electric_car, 'Fleet & vehicles',
          'Registry, battery, maintenance', const FleetScreen()),
      (Icons.sell_outlined, 'Pricing & promos',
          'Fares, surge zones, promo codes', const PricingScreen()),
      (Icons.account_balance_outlined, 'Finance',
          'Revenue, payouts, VAT', const FinanceScreen()),
      (Icons.support_agent, 'Support & disputes',
          'Tickets, lost items, safety', const SupportScreen()),
      (Icons.insights, 'Analytics',
          'Demand, CO₂, charging, retention', const AnalyticsScreen()),
      (Icons.admin_panel_settings_outlined, 'Roles & permissions',
          'Super-admin · Ops · Finance · Support', null),
      (Icons.settings_outlined, 'Settings', 'Regions, currency, VAT', null),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            for (final (icon, title, subtitle, screen) in items)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: EvcColors.mist,
                      borderRadius: BorderRadius.circular(EvcRadius.sm),
                    ),
                    child: Icon(icon, color: EvcColors.ink),
                  ),
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(subtitle),
                  trailing: const Icon(Icons.chevron_right,
                      color: EvcColors.slate),
                  onTap: screen == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => screen),
                          ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: EvcColors.danger),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}