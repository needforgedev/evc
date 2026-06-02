import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_controller.dart';
import 'driver_detail_screen.dart';

/// Driver management — approval queue + roster.
class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminControllerProvider);
    final ctrl = ref.read(adminControllerProvider.notifier);
    final pending = admin.pending;
    final roster = admin.drivers
        .where((d) => d.status != DriverAccountStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (pending.isNotEmpty) ...[
              Text('Pending approval · ${pending.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              for (final d in pending)
                _PendingCard(
                  driver: d,
                  onApprove: () => ctrl.approveDriver(d.name),
                  onReject: () => ctrl.rejectDriver(d.name),
                  onTap: () => _open(context, d),
                ),
              const SizedBox(height: 20),
            ],
            const Text('All drivers',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final d in roster) _RosterTile(driver: d, onTap: () => _open(context, d)),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, DriverRecord d) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DriverDetailScreen(driver: d)),
      );
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.driver,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  final DriverRecord driver;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: driver.avatarColor,
                    child: Text(driver.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('${driver.vehicleModel} · ${driver.ownerLabel}',
                            style: const TextStyle(
                                color: EvcColors.slate, fontSize: 13)),
                        Text(driver.appliedLabel,
                            style: const TextStyle(
                                color: EvcColors.slate, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: EvcColors.danger,
                        side: const BorderSide(color: EvcColors.line),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44)),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({required this.driver, required this.onTap});
  final DriverRecord driver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: driver.avatarColor,
          child: Text(driver.initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        title: Text(driver.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '★ ${driver.rating} · ${driver.totalTrips} trips · ${driver.plate}'),
        trailing: StatusChip(status: driver.status),
      ),
    );
  }
}

/// Coloured chip for a driver's account status — reused on the detail screen.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final DriverAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DriverAccountStatus.pending => ('Pending', EvcColors.warning),
      DriverAccountStatus.active => ('Active', EvcColors.primaryDark),
      DriverAccountStatus.suspended => ('Suspended', EvcColors.danger),
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