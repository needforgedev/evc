import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../../state/admin_session.dart';
import '../../state/locale_provider.dart';
import '../analytics/analytics_screen.dart';
import '../auth/login_screen.dart';
import '../finance/finance_screen.dart';
import '../fleet/fleet_screen.dart';
import '../pricing/pricing_screen.dart';
import '../support/support_screen.dart';

/// Secondary ops sections.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await AdminAuth.signOut();
    ref.invalidate(currentAdminProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    final langLabel =
        ref.watch(localeProvider).languageCode == 'ar' ? 'العربية' : 'English';
    final items = <(IconData, String, String, Widget?)>[
      (Icons.electric_car, tr.fleetVehicles, tr.fleetSub, const FleetScreen()),
      (Icons.sell_outlined, tr.pricingPromos, tr.pricingSub,
          const PricingScreen()),
      (Icons.account_balance_outlined, tr.finance, tr.financeSub,
          const FinanceScreen()),
      (Icons.support_agent, tr.supportDisputes, tr.supportSub,
          const SupportScreen()),
      (Icons.insights, tr.analytics, tr.analyticsSub, const AnalyticsScreen()),
      (Icons.admin_panel_settings_outlined, tr.rolesPermissions, tr.rolesSub,
          null),
      (Icons.settings_outlined, tr.settings, tr.settingsSub, null),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tr.more)),
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
                  child: const Icon(Icons.language, color: EvcColors.ink),
                ),
                title: Text(tr.language,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(langLabel),
                trailing:
                    const Icon(Icons.chevron_right, color: EvcColors.slate),
                onTap: () => _pickLanguage(context, ref),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _signOut(context, ref),
                style: TextButton.styleFrom(foregroundColor: EvcColors.danger),
                child: Text(tr.signOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}