enum TicketType { lostItem, safety, fare, general }

enum TicketStatus { open, pending, resolved }

/// A support / dispute item in the Admin console.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.type,
    required this.fromName,
    required this.status,
    required this.timeLabel,
  });

  final String id;
  final String subject;
  final TicketType type;
  final String fromName;
  final TicketStatus status;
  final String timeLabel;
}