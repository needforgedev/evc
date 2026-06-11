import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';

/// Pricing & promotions — real, editable config (rates, tiers, surge, promos)
/// backed by the `pricing` / `ride_tiers` / `surge_rules` / `promo_codes` tables.
/// Every change is logged to `config_audit` (shown under "Recent changes").
class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(adminPricingProvider);
    ref.invalidate(adminTiersProvider);
    ref.invalidate(adminPromosProvider);
    ref.invalidate(adminSurgesProvider);
    ref.invalidate(adminConfigAuditProvider);
  }

  void _toast(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = ref.watch(adminPricingProvider);
    final tiers = ref.watch(adminTiersProvider);
    final surges = ref.watch(adminSurgesProvider);
    final promos = ref.watch(adminPromosProvider);
    final audit = ref.watch(adminConfigAuditProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pricing & promos')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            // ── Base rates ──
            _header('Base rates', actionLabel: 'Edit', onAction: () async {
              final p = pricing.value;
              if (p == null) return;
              final res = await showDialog<_Rates>(
                context: context,
                builder: (_) => _EditRatesDialog(current: p),
              );
              if (res == null) return;
              await AdminConfigActions.updatePricing(
                baseFare: res.baseFare,
                perKm: res.perKm,
                perMin: res.perMin,
                minFare: res.minFare,
                vatRate: res.vatRate,
              );
              _refresh(ref);
              if (context.mounted) _toast(context, 'Base rates updated');
            }),
            pricing.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (p) => Column(
                children: [
                  Row(
                    children: [
                      _rate('AED ${p.baseFare.toStringAsFixed(2)}', 'Base'),
                      const SizedBox(width: 12),
                      _rate('AED ${p.perKm.toStringAsFixed(2)}', 'per km'),
                      const SizedBox(width: 12),
                      _rate('AED ${p.perMin.toStringAsFixed(2)}', 'per min'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _rate('AED ${p.minFare.toStringAsFixed(2)}', 'min fare'),
                      const SizedBox(width: 12),
                      _rate('${(p.vatRate * 100).toStringAsFixed(0)}%', 'VAT'),
                      const SizedBox(width: 12),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),

            // ── Ride tiers ──
            const SizedBox(height: 24),
            _header('Ride tiers'),
            tiers.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (list) => Column(
                children: [
                  for (final t in list)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(t.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${t.multiplier.toStringAsFixed(2)}× · ${t.seats} seats'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.tune, size: 20),
                              tooltip: 'Edit multiplier',
                              onPressed: () async {
                                final m = await showDialog<double>(
                                  context: context,
                                  builder: (_) => _EditMultiplierDialog(
                                      name: t.name, current: t.multiplier),
                                );
                                if (m == null) return;
                                await AdminConfigActions.updateTier(t.id, multiplier: m);
                                _refresh(ref);
                                if (context.mounted) _toast(context, '${t.name} updated');
                              },
                            ),
                            Switch(
                              value: t.active,
                              onChanged: (v) async {
                                await AdminConfigActions.updateTier(t.id, active: v);
                                _refresh(ref);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Surge by zone ──
            const SizedBox(height: 24),
            _header('Surge by zone'),
            surges.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (list) => list.isEmpty
                  ? const _Empty('No surge zones configured.')
                  : Column(
                      children: [
                        for (final z in list)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.place_outlined,
                                  color: EvcColors.ink),
                              title: Text(z.zone,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _multBadge(z.multiplier),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: z.active,
                                    onChanged: (v) async {
                                      await AdminConfigActions.setSurgeActive(z.id, v);
                                      _refresh(ref);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // ── Promo codes ──
            const SizedBox(height: 24),
            _header('Promo codes', actionLabel: 'New', onAction: () async {
              final res = await showDialog<_NewPromo>(
                context: context,
                builder: (_) => const _NewPromoDialog(),
              );
              if (res == null) return;
              try {
                await AdminConfigActions.createPromo(
                  code: res.code,
                  description: res.description,
                  discountType: res.discountType,
                  value: res.value,
                  maxDiscount: res.maxDiscount,
                );
                _refresh(ref);
                if (context.mounted) _toast(context, 'Promo ${res.code.toUpperCase()} created');
              } catch (e) {
                if (context.mounted) _toast(context, 'Could not create: $e');
              }
            }),
            promos.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (list) => list.isEmpty
                  ? const _Empty('No promo codes yet.')
                  : Column(
                      children: [
                        for (final p in list)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.local_offer_outlined,
                                  color: EvcColors.ink),
                              title: Text(p.code,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, letterSpacing: 1)),
                              subtitle: Text(
                                  '${p.description ?? _promoLabel(p)} · ${p.redemptions} used'),
                              trailing: Switch(
                                value: p.active,
                                onChanged: (v) async {
                                  await AdminConfigActions.setPromoActive(p.id, v);
                                  _refresh(ref);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // ── Recent changes (audit) ──
            const SizedBox(height: 24),
            _header('Recent changes'),
            audit.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (list) => list.isEmpty
                  ? const _Empty('No config changes logged yet.')
                  : Column(
                      children: [
                        for (final c in list)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.history,
                                size: 18, color: EvcColors.slate),
                            title: Text('${_friendly(c.table)} · ${c.action.toLowerCase()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            trailing: Text(c.when,
                                style: const TextStyle(
                                    color: EvcColors.slate, fontSize: 12)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _promoLabel(AdminPromo p) => p.discountType == 'percent'
      ? '${p.value.toStringAsFixed(0)}% off'
      : 'AED ${p.value.toStringAsFixed(0)} off';

  String _friendly(String table) => switch (table) {
        'pricing' => 'Base rates',
        'ride_tiers' => 'Ride tier',
        'promo_codes' => 'Promo',
        'surge_rules' => 'Surge',
        _ => table,
      };

  Widget _header(String title, {String? actionLabel, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const Spacer(),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _multBadge(double m) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: m > 1
              ? EvcColors.warning.withValues(alpha: 0.14)
              : EvcColors.mist,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('${m.toStringAsFixed(2)}×',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: m > 1 ? const Color(0xFFB78000) : EvcColors.slate)),
      );

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

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: EvcColors.slate)),
      );
}

// ───────────────────────── dialogs ─────────────────────────

class _Rates {
  const _Rates(this.baseFare, this.perKm, this.perMin, this.minFare, this.vatRate);
  final double baseFare, perKm, perMin, minFare, vatRate;
}

class _EditRatesDialog extends StatefulWidget {
  const _EditRatesDialog({required this.current});
  final PricingConfig current;
  @override
  State<_EditRatesDialog> createState() => _EditRatesDialogState();
}

class _EditRatesDialogState extends State<_EditRatesDialog> {
  late final _base = TextEditingController(text: widget.current.baseFare.toString());
  late final _perKm = TextEditingController(text: widget.current.perKm.toString());
  late final _perMin = TextEditingController(text: widget.current.perMin.toString());
  late final _minFare = TextEditingController(text: widget.current.minFare.toString());
  late final _vat = TextEditingController(
      text: (widget.current.vatRate * 100).toStringAsFixed(0));

  @override
  void dispose() {
    for (final c in [_base, _perKm, _perMin, _minFare, _vat]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit base rates'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _num(_base, 'Base fare (AED)'),
            _num(_perKm, 'Per km (AED)'),
            _num(_perMin, 'Per minute (AED)'),
            _num(_minFare, 'Minimum fare (AED)'),
            _num(_vat, 'VAT (%)'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            double d(TextEditingController c, double fb) =>
                double.tryParse(c.text.trim()) ?? fb;
            Navigator.pop(
              context,
              _Rates(
                d(_base, widget.current.baseFare),
                d(_perKm, widget.current.perKm),
                d(_perMin, widget.current.perMin),
                d(_minFare, widget.current.minFare),
                d(_vat, widget.current.vatRate * 100) / 100,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _num(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _EditMultiplierDialog extends StatefulWidget {
  const _EditMultiplierDialog({required this.name, required this.current});
  final String name;
  final double current;
  @override
  State<_EditMultiplierDialog> createState() => _EditMultiplierDialogState();
}

class _EditMultiplierDialogState extends State<_EditMultiplierDialog> {
  late final _c = TextEditingController(text: widget.current.toString());
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.name} multiplier'),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: const InputDecoration(labelText: 'Multiplier (e.g. 1.50)'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, double.tryParse(_c.text.trim()) ?? widget.current),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _NewPromo {
  const _NewPromo(this.code, this.description, this.discountType, this.value,
      this.maxDiscount);
  final String code;
  final String? description;
  final String discountType;
  final double value;
  final double? maxDiscount;
}

class _NewPromoDialog extends StatefulWidget {
  const _NewPromoDialog();
  @override
  State<_NewPromoDialog> createState() => _NewPromoDialogState();
}

class _NewPromoDialogState extends State<_NewPromoDialog> {
  final _code = TextEditingController();
  final _desc = TextEditingController();
  final _value = TextEditingController();
  final _maxDiscount = TextEditingController();
  String _type = 'percent';

  @override
  void dispose() {
    for (final c in [_code, _desc, _value, _maxDiscount]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New promo code'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code (e.g. GREEN20)'),
            ),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Type:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Percent %')),
                    DropdownMenuItem(value: 'flat', child: Text('Flat AED')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'percent'),
                ),
              ],
            ),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                  labelText: _type == 'percent' ? 'Percent off' : 'AED off'),
            ),
            TextField(
              controller: _maxDiscount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(labelText: 'Max discount AED (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final code = _code.text.trim();
            final value = double.tryParse(_value.text.trim()) ?? 0;
            if (code.isEmpty || value <= 0) {
              Navigator.pop(context);
              return;
            }
            Navigator.pop(
              context,
              _NewPromo(
                code,
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                _type,
                value,
                double.tryParse(_maxDiscount.text.trim()),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}