import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';

/// Admin station management (ADM-05) — live charger status, per-station rate
/// (editable), and reserve/queue length.
class StationManagementScreen extends ConsumerWidget {
  const StationManagementScreen({super.key});

  Future<void> _editRate(
      BuildContext context, WidgetRef ref, AdminStation s) async {
    final controller =
        TextEditingController(text: s.pricePerKwh.toStringAsFixed(2));
    final value = await showDialog<double>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('Rate · ${s.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Customer rate',
            prefixText: 'AED ',
            suffixText: '/ kWh',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.of(dctx).pop(double.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    try {
      await EvcCharging.adminSetStationRate(s.id, value);
      // The realtime stream refreshes the list automatically.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(adminStationsProvider);
    final queue = ref.watch(adminChargingQueueProvider).value ?? const [];

    int queuedAt(String stationId) => queue
        .where((e) => e.stationId == stationId && e.status == 'queued')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Charging stations')),
      body: SafeArea(
        top: false,
        child: stationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load stations.\n$e')),
          data: (stations) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              for (final s in stations)
                _StationRow(
                  station: s,
                  queued: queuedAt(s.id),
                  onEditRate: () => _editRate(context, ref, s),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.station,
    required this.queued,
    required this.onEditRate,
  });

  final AdminStation station;
  final int queued;
  final VoidCallback onEditRate;

  @override
  Widget build(BuildContext context) {
    final available = station.hasAvailability;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: EvcColors.mist,
                    borderRadius: BorderRadius.circular(EvcRadius.sm),
                  ),
                  child: const Icon(Icons.ev_station, color: EvcColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.name,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${station.network} · ${station.powerKw} kW',
                          style: const TextStyle(
                              color: EvcColors.slate, fontSize: 13)),
                    ],
                  ),
                ),
                _statusChip(available),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric('${station.available}/${station.total}', 'Available'),
                _divider(),
                _metric('$queued', 'Queued'),
                _divider(),
                _metric('AED ${station.pricePerKwh.toStringAsFixed(2)}', '/ kWh'),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onEditRate,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Rate'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 38)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(bool available) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (available ? EvcColors.primary : EvcColors.danger)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(available ? 'Available' : 'Full',
            style: TextStyle(
                color: available ? EvcColors.primaryDark : EvcColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      );

  Widget _metric(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(label,
              style: const TextStyle(color: EvcColors.slate, fontSize: 11)),
        ],
      );

  Widget _divider() => Container(
      width: 1,
      height: 28,
      color: EvcColors.line,
      margin: const EdgeInsets.symmetric(horizontal: 14));
}
