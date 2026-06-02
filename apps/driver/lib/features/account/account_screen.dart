import 'package:flutter/material.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

/// Driver account — profile, vehicle, ratings and settings.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFF2563EB),
                  child: Text('OA',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Omar Al Farsi',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Pearl White Tesla Model 3 · K 48213',
                          style: TextStyle(color: EvcColors.slate)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _stat('4.93', 'Rating', Icons.star, highlight: true),
                const SizedBox(width: 12),
                _stat('2,841', 'Trips', Icons.route_outlined),
                const SizedBox(width: 12),
                _stat('94%', 'Acceptance', Icons.task_alt),
              ],
            ),
            const SizedBox(height: 24),
            _tile(Icons.directions_car_outlined, 'My vehicle'),
            _tile(Icons.badge_outlined, 'Documents & compliance'),
            _tile(Icons.account_balance_outlined, 'Payouts & bank'),
            _tile(Icons.receipt_long_outlined, 'Tax summary'),
            _tile(Icons.insights_outlined, 'Performance'),
            _tile(Icons.help_outline, 'Support & disputes'),
            _tile(Icons.settings_outlined, 'Settings'),
            const SizedBox(height: 12),
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

  Widget _stat(String value, String label, IconData icon,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Icon(icon,
                color: highlight ? EvcColors.primaryDark : EvcColors.ink,
                size: 20),
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

  Widget _tile(IconData icon, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: EvcColors.ink),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: EvcColors.slate),
      onTap: () {},
    );
  }
}