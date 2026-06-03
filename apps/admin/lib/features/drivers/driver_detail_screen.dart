import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';
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
                  for (final doc in const [
                    'Driving license',
                    'RTA driver permit',
                    'Emirates ID',
                    'Vehicle registration & insurance',
                  ])
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                            pending
                                ? Icons.hourglass_bottom
                                : Icons.check_circle,
                            color: pending
                                ? EvcColors.warning
                                : EvcColors.primary),
                        title: Text(doc),
                        trailing: Text(pending ? 'In review' : 'Verified',
                            style: TextStyle(
                                color: pending
                                    ? EvcColors.warning
                                    : EvcColors.primaryDark,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
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
