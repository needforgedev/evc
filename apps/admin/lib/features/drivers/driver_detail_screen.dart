import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';
import '../../state/admin_docs.dart';
import 'drivers_screen.dart' show StatusChip;

/// Driver profile + moderation actions (approve / reject / suspend / reactivate).
class DriverDetailScreen extends ConsumerWidget {
  const DriverDetailScreen({super.key, required this.driver});

  final DriverRecord driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reflect live status from the providers list (falls back to passed-in).
    final current = ref.watch(adminDriversProvider).value?.firstWhere(
              (d) => d.id == driver.id,
              orElse: () => driver,
            ) ??
        driver;
    final pending = current.status == DriverAccountStatus.pending;

    Future<void> act(String status, String msg) async {
      try {
        await AdminActions.setDriverStatus(current.id, status);
        ref.invalidate(adminDriversProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Driver')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: current.avatarColor,
                        child: Text(current.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(current.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 20)),
                            const SizedBox(height: 4),
                            StatusChip(status: current.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!pending)
                    Row(
                      children: [
                        _stat('★ ${current.rating}', 'Rating'),
                        _stat('${current.totalTrips}', 'Trips'),
                        _stat(current.ownerLabel, 'Vehicle'),
                      ],
                    ),
                  if (!pending) const SizedBox(height: 20),
                  const Text('Vehicle',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.electric_car, color: EvcColors.ink),
                      title: Text(current.vehicleModel,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${current.ownerLabel} · ${current.plate}'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Documents',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  _DriverDocsSection(driverId: current.id),
                ],
              ),
            ),
            _actions(context, current, act),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, DriverRecord d,
      Future<void> Function(String, String) act) {
    final children = switch (d.status) {
      DriverAccountStatus.pending => [
          Expanded(
            child: OutlinedButton(
              onPressed: () => act('suspended', '${d.name} rejected'),
              style:
                  OutlinedButton.styleFrom(foregroundColor: EvcColors.danger),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () =>
                  act('active', '${d.name} approved — can now go online'),
              child: const Text('Approve driver'),
            ),
          ),
        ],
      DriverAccountStatus.active => [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: EvcColors.danger),
              onPressed: () => act('suspended', '${d.name} suspended'),
              child: const Text('Suspend driver'),
            ),
          ),
        ],
      DriverAccountStatus.suspended => [
          Expanded(
            child: FilledButton(
              onPressed: () => act('active', '${d.name} reactivated'),
              child: const Text('Reactivate driver'),
            ),
          ),
        ],
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(children: children),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(label,
              style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Real uploaded documents for a driver — view the file + per-doc approve/reject.
class _DriverDocsSection extends ConsumerWidget {
  const _DriverDocsSection({required this.driverId});
  final String driverId;

  Future<void> _view(BuildContext context, String path) async {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: FutureBuilder<String>(
          future: AdminDocActions.signedUrl(path),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox(
                  height: 220, child: Center(child: CircularProgressIndicator()));
            }
            return InteractiveViewer(
              child: Image.network(snap.data!,
                  errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Could not load file (or not an image).'))),
            );
          },
        ),
      ),
    );
  }

  Future<void> _review(
      BuildContext context, WidgetRef ref, String docId, String status) async {
    await AdminDocActions.review(docId, status);
    ref.invalidate(driverDocsProvider(driverId));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Document $status')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(driverDocsProvider(driverId));
    return docsAsync.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Could not load documents.\n$e'),
      data: (docs) {
        final byType = {for (final d in docs) d.type: d};
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in kDocLabels.entries)
              _docCard(context, ref, entry.key, entry.value, byType[entry.key]),
          ],
        );
      },
    );
  }

  Widget _docCard(BuildContext context, WidgetRef ref, String type,
      String label, DriverDoc? doc) {
    final uploaded = doc != null;
    final (statusText, statusColor) = switch (doc?.reviewStatus) {
      'approved' => ('Verified', EvcColors.primaryDark),
      'rejected' => ('Rejected', EvcColors.danger),
      'pending' => ('In review', EvcColors.warning),
      _ => ('Not uploaded', EvcColors.slate),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        border: Border.all(color: EvcColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(uploaded ? Icons.check_circle : Icons.circle_outlined,
                  size: 15, color: statusColor),
              const SizedBox(width: 6),
              Text(statusText,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w700)),
            ],
          ),
          if (uploaded) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _view(context, doc.storagePath),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                ),
                OutlinedButton(
                  onPressed: () => _review(context, ref, doc.id, 'rejected'),
                  style:
                      OutlinedButton.styleFrom(foregroundColor: EvcColors.danger),
                  child: const Text('Reject'),
                ),
                FilledButton(
                  onPressed: () => _review(context, ref, doc.id, 'approved'),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
