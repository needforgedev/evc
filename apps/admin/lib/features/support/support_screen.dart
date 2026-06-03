import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/admin_data.dart';

/// Support & disputes console — real ticket queue.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(adminTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Support & disputes')),
      body: SafeArea(
        top: false,
        child: ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load tickets.\n$e')),
          data: (tickets) {
            if (tickets.isEmpty) {
              return const Center(
                  child: Text('No support tickets.',
                      style: TextStyle(color: EvcColors.slate)));
            }
            final open =
                tickets.where((t) => t.status != TicketStatus.resolved).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EvcColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(EvcRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          color: Color(0xFFB78000)),
                      const SizedBox(width: 12),
                      Text('$open open ticket${open == 1 ? '' : 's'} in the queue',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final t in tickets) _TicketCard(ticket: t),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (ticket.type) {
      TicketType.lostItem => (Icons.work_outline, EvcColors.ink),
      TicketType.safety => (Icons.shield_outlined, EvcColors.danger),
      TicketType.fare => (Icons.receipt_long_outlined, EvcColors.ink),
      TicketType.general => (Icons.chat_bubble_outline, EvcColors.ink),
    };
    final (statusLabel, statusColor) = switch (ticket.status) {
      TicketStatus.open => ('Open', EvcColors.danger),
      TicketStatus.pending => ('Pending', EvcColors.warning),
      TicketStatus.resolved => ('Resolved', EvcColors.primaryDark),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: tint.withValues(alpha: 0.10),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('#${ticket.id} · ${ticket.fromName} · ${ticket.timeLabel}',
                      style: const TextStyle(
                          color: EvcColors.slate, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
