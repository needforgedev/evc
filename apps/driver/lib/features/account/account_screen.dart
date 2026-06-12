import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../../state/driver_account.dart';
import '../../state/locale_provider.dart';
import '../documents/documents_screen.dart';
import '../onboarding/splash_screen.dart';

/// Driver account — real profile, vehicle, ratings and settings.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await DriverActions.signOut();
    ref.invalidate(currentDriverProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _pickLanguage(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EvcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) {
        final current = ref.read(localeProvider).languageCode;
        Widget option(String code, String label) => ListTile(
              title: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: current == code
                  ? const Icon(Icons.check_circle, color: EvcColors.primary)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).set(Locale(code));
                Navigator.of(sheet).pop();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              option('en', 'English'),
              option('ar', 'العربية'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = AppStrings.of(context);
    final driverAsync = ref.watch(currentDriverProvider);
    final langLabel =
        ref.watch(localeProvider).languageCode == 'ar' ? 'العربية' : 'English';

    return Scaffold(
      appBar: AppBar(title: Text(tr.account)),
      body: SafeArea(
        top: false,
        child: driverAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load account.\n$e')),
          data: (d) => d == null
              ? const Center(child: Text('Not signed in.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: EvcColors.ink,
                          child: Text(d.initials,
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
                              Text(d.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(
                                  d.hasVehicle
                                      ? '${d.vehicleModel} · ${d.plate}'
                                      : d.phone,
                                  style:
                                      const TextStyle(color: EvcColors.slate)),
                            ],
                          ),
                        ),
                        _StatusChip(status: d.status),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _stat(d.rating.toStringAsFixed(2), tr.rating, Icons.star,
                            highlight: true),
                        const SizedBox(width: 12),
                        _stat('${d.totalTrips}', tr.trips, Icons.route_outlined),
                        const SizedBox(width: 12),
                        _stat('${d.acceptanceRate.toStringAsFixed(0)}%',
                            tr.acceptance, Icons.task_alt),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _tile(Icons.directions_car_outlined, tr.myVehicle),
                    _tile(Icons.badge_outlined, tr.documentsCompliance,
                        onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const DocumentsScreen()),
                            )),
                    _tile(Icons.account_balance_outlined, tr.payoutsBank),
                    _tile(Icons.receipt_long_outlined, tr.taxSummary),
                    _tile(Icons.language, tr.language,
                        trailing: langLabel,
                        onTap: () => _pickLanguage(context, ref)),
                    _tile(Icons.help_outline, tr.supportDisputes),
                    _tile(Icons.settings_outlined, tr.settings),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => _signOut(context, ref),
                        style: TextButton.styleFrom(
                            foregroundColor: EvcColors.danger),
                        child: Text(tr.signOut),
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

  Widget _tile(IconData icon, String label,
      {VoidCallback? onTap, String? trailing}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: EvcColors.ink),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: const TextStyle(color: EvcColors.slate)),
          const Icon(Icons.chevron_right, color: EvcColors.slate),
        ],
      ),
      onTap: onTap ?? () {},
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final DriverAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings.of(context);
    final (label, color) = switch (status) {
      DriverAccountStatus.pending => (tr.statusPending, EvcColors.warning),
      DriverAccountStatus.active => (tr.statusActive, EvcColors.primaryDark),
      DriverAccountStatus.suspended => (tr.statusSuspended, EvcColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
