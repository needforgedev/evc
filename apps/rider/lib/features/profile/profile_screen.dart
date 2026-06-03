import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/rider_account.dart';
import '../../state/rider_history.dart';
import '../history/history_screen.dart';
import '../onboarding/splash_screen.dart';

/// Rider account — real profile, sustainability stats, and settings menu.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await RiderActions.signOut();
    ref.invalidate(currentRiderProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderAsync = ref.watch(currentRiderProvider);
    final history = ref.watch(rideHistoryProvider).value ?? const [];
    final co2 = history.fold<double>(0, (s, t) => s + t.co2SavedKg);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: riderAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load account.\n$e')),
          data: (rider) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: EvcColors.ink,
                    child: Text(rider?.initials ?? 'EV',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rider?.fullName ?? 'Rider',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(rider?.phone ?? '',
                            style: const TextStyle(color: EvcColors.slate)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: EvcColors.warning),
                      const SizedBox(width: 4),
                      Text(rider?.rating.toStringAsFixed(1) ?? '5.0',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _stat('${rider?.totalTrips ?? 0}', 'Trips',
                        Icons.route_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stat('${co2.toStringAsFixed(0)} kg', 'CO₂ saved',
                        Icons.eco_rounded,
                        highlight: true),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _tile(context, Icons.receipt_long_outlined, 'Your trips',
                  onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
                      )),
              _tile(context, Icons.credit_card, 'Payment methods'),
              _tile(context, Icons.bookmark_border, 'Saved places'),
              _tile(context, Icons.shield_outlined, 'Safety'),
              _tile(context, Icons.card_giftcard, 'Refer & earn'),
              _tile(context, Icons.help_outline, 'Help'),
              _tile(context, Icons.settings_outlined, 'Settings'),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _signOut(context, ref),
                  style:
                      TextButton.styleFrom(foregroundColor: EvcColors.danger),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon,
      {bool highlight = false}) {
    return Container(
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
          Icon(icon, color: highlight ? EvcColors.primaryDark : EvcColors.ink),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: EvcColors.slate)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: EvcColors.ink),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: EvcColors.slate),
      onTap: onTap ?? () {},
    );
  }
}
