import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../../state/admin_data.dart';

/// The regulatory clock — drivers whose documents are expiring (60/30/14/7)
/// or already expired (auto-removed from dispatch), most urgent first.
class ComplianceScreen extends ConsumerWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = AppStrings.of(context);
    final async = ref.watch(adminComplianceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr.compliance)),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminComplianceProvider),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (rows) => rows.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text(tr.noExpiring,
                          style: const TextStyle(color: EvcColors.slate)),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: rows.length,
                    itemBuilder: (context, i) => _row(tr, rows[i]),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _row(AppStrings tr, ComplianceRow r) {
    final days = r.expiresAt.difference(DateTime.now()).inDays;
    final color = r.isExpired
        ? EvcColors.danger
        : (days <= 7 ? EvcColors.danger : const Color(0xFFB78000));
    final badge = r.isExpired ? tr.expired : tr.expiresInDays(days < 0 ? 0 : days);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(EvcRadius.sm),
          ),
          child: Icon(r.isExpired ? Icons.error_outline : Icons.schedule,
              color: color),
        ),
        title: Text(r.driverName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${r.docLabel} · ${_fmt(r.expiresAt)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
