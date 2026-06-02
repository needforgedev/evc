import 'package:flutter/widgets.dart';

enum PaymentType { cash, card, applePay, wallet }

/// A rider payment option.
@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.type,
    required this.label,
    required this.icon,
    this.detail = '',
  });

  final PaymentType type;
  final String label;

  /// Secondary text, e.g. "•••• 4242".
  final String detail;
  final IconData icon;
}