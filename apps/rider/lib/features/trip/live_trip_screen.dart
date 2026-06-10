import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/active_trip_provider.dart';
import '../../state/assigned_driver_provider.dart';
import '../../state/booking_controller.dart';

/// Live trip screen driven by the real `trips` row (Realtime).
/// Step 3: real driver/vehicle card, status-aware tracking, receipt + rating.
/// (The moving dot is status-animated on the placeholder map until device GPS
/// + real maps land in the Geo milestone.)
class LiveTripScreen extends ConsumerStatefulWidget {
  const LiveTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends ConsumerState<LiveTripScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _car =
      AnimationController(vsync: this, duration: const Duration(seconds: 45));
  bool _rated = false;

  @override
  void dispose() {
    _car.dispose();
    super.dispose();
  }

  void _syncCar(LiveTripStatus s) {
    switch (s) {
      case LiveTripStatus.ongoing:
        if (!_car.isAnimating && _car.value < 1) _car.forward();
      case LiveTripStatus.completed:
        _car
          ..stop()
          ..value = 1;
      default:
        _car
          ..stop()
          ..value = 0;
    }
  }

  Future<void> _cancel() async {
    try {
      await EvcTrips.cancel(widget.tripId);
    } catch (_) {/* leaving the screen anyway */}
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _submitRating(
      String driverId, int stars, List<String> tags, num tip) async {
    try {
      await EvcTrips.rate(widget.tripId, driverId, stars, tags: tags);
      if (tip > 0) await EvcTrips.addTip(widget.tripId, tip);
      if (!mounted) return;
      ref.invalidate(tripPaymentProvider(widget.tripId)); // refresh receipt tip
      setState(() => _rated = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not submit: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingControllerProvider);
    final trip = ref.watch(tripStreamProvider(widget.tripId)).value;
    final status = trip?.status ?? LiveTripStatus.requested;

    // Drive the animated dot off the live status.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCar(status));

    double? carProgress;
    if (status == LiveTripStatus.enroute || status == LiveTripStatus.arrived) {
      carProgress = 0;
    } else if (status == LiveTripStatus.ongoing) {
      carProgress = _car.value;
    } else if (status == LiveTripStatus.completed) {
      carProgress = 1;
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _car,
              builder: (_, _) => PlaceholderMap(
                pickup: booking.pickup,
                destination: booking.destination,
                showRoute: true,
                carProgress: status == LiveTripStatus.ongoing
                    ? _car.value
                    : carProgress,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _StatusPill(status: status),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _panel(trip, status),
          ),
        ],
      ),
    );
  }

  Widget _panel(ActiveTrip? trip, LiveTripStatus status) {
    final body = switch (status) {
      LiveTripStatus.requested ||
      LiveTripStatus.matched =>
        _searching(trip),
      LiveTripStatus.enroute || LiveTripStatus.arrived => _driverPanel(trip, status),
      LiveTripStatus.ongoing => _ongoingPanel(trip),
      LiveTripStatus.completed => _completedPanel(trip),
      LiveTripStatus.canceled => _canceledPanel(),
    };

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: body,
          ),
        ),
      ),
    );
  }

  // ───────────────────────── panels ─────────────────────────

  List<Widget> _searching(ActiveTrip? trip) => [
        Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: EvcColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(_headline(trip?.status ?? LiveTripStatus.requested),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          trip == null
              ? 'Creating your trip…'
              : 'To ${trip.destName}  ·  ${(trip.distanceKm ?? 0).toStringAsFixed(1)} km',
          style: const TextStyle(color: EvcColors.slate),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _cancel, child: const Text('Cancel ride')),
      ];

  List<Widget> _driverPanel(ActiveTrip? trip, LiveTripStatus status) {
    final arrived = status == LiveTripStatus.arrived;
    return [
      Text(_headline(status),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(arrived ? 'Meet your driver at the pickup point.' : 'On the way to you.',
          style: const TextStyle(color: EvcColors.slate)),
      const SizedBox(height: 14),
      if (trip?.driverId != null)
        _DriverCard(driverId: trip!.driverId!, vehicleId: trip.vehicleId),
      const SizedBox(height: 14),
      Row(
        children: [
          if (trip?.pin != null) ...[
            _PinBox(pin: trip!.pin!),
            const SizedBox(width: 12),
          ],
          Expanded(child: _callButton(trip)),
        ],
      ),
      const SizedBox(height: 10),
      Center(
        child: TextButton(
          onPressed: _cancel,
          child: const Text('Cancel ride',
              style: TextStyle(color: EvcColors.slate)),
        ),
      ),
    ];
  }

  List<Widget> _ongoingPanel(ActiveTrip? trip) {
    final mins = trip?.durationMin;
    return [
      Row(
        children: [
          const Icon(Icons.navigation_rounded, color: EvcColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mins != null ? 'On your way · ~$mins min' : 'On your way',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text('To ${trip?.destName ?? ''}',
          style: const TextStyle(color: EvcColors.slate)),
      const SizedBox(height: 14),
      if (trip?.driverId != null)
        _DriverCard(
            driverId: trip!.driverId!, vehicleId: trip.vehicleId, compact: true),
      const SizedBox(height: 12),
      _callButton(trip),
    ];
  }

  List<Widget> _completedPanel(ActiveTrip? trip) => [
        Row(
          children: const [
            Icon(Icons.check_circle, color: EvcColors.primary),
            SizedBox(width: 12),
            Text('Trip complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 14),
        if (trip != null) _Receipt(trip: trip),
        const SizedBox(height: 16),
        if (trip?.driverId != null && !_rated)
          _RatingBar(
            onSubmit: (stars, tags, tip) =>
                _submitRating(trip!.driverId!, stars, tags, tip),
          )
        else if (_rated)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Thanks for rating your driver ⭐',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Text('Done'),
        ),
      ];

  List<Widget> _canceledPanel() => [
        Row(
          children: const [
            Icon(Icons.cancel, color: EvcColors.slate),
            SizedBox(width: 12),
            Text('Trip canceled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Text('Done'),
        ),
      ];

  Widget _callButton(ActiveTrip? trip) {
    final driverId = trip?.driverId;
    if (driverId == null) return const SizedBox.shrink();
    final async = ref.watch(assignedDriverProvider((driverId, trip!.vehicleId)));
    final phone = async.value?.phone;
    return OutlinedButton.icon(
      onPressed: phone == null ? null : () => _dial(phone),
      icon: const Icon(Icons.call, size: 18),
      label: const Text('Call driver'),
      style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48)),
    );
  }

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open dialer.')));
      }
    }
  }
}

String _headline(LiveTripStatus s) => switch (s) {
      LiveTripStatus.requested => 'Finding your EV…',
      LiveTripStatus.matched => 'Driver found — confirming…',
      LiveTripStatus.enroute => 'Your driver is on the way',
      LiveTripStatus.arrived => 'Your driver has arrived',
      LiveTripStatus.ongoing => 'On the way to your destination',
      LiveTripStatus.completed => "You've arrived",
      LiveTripStatus.canceled => 'Trip canceled',
    };

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final LiveTripStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EvcColors.ink,
        borderRadius: BorderRadius.circular(EvcRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: EvcColors.primary, size: 18),
          const SizedBox(width: 6),
          Text(_headline(status),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Real driver + vehicle card (name, rating, EV vehicle/plate, range assurance).
class _DriverCard extends ConsumerWidget {
  const _DriverCard({
    required this.driverId,
    required this.vehicleId,
    this.compact = false,
  });

  final String driverId;
  final String? vehicleId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(assignedDriverProvider((driverId, vehicleId))).value;
    if (d == null) {
      return Container(
        height: 64,
        decoration: BoxDecoration(
          color: EvcColors.mist,
          borderRadius: BorderRadius.circular(EvcRadius.md),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EvcColors.mist,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        border: Border.all(color: EvcColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: EvcColors.primary,
                child: Text(d.initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFF5A623)),
                        const SizedBox(width: 3),
                        Text(d.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('${d.vehicleModel} · ${d.plate}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: EvcColors.slate, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!compact && d.rangeKm > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: EvcColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(EvcRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 16, color: EvcColors.primary),
                  const SizedBox(width: 6),
                  Text('${d.rangeKm} km range · covers your trip',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: EvcColors.ink)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({required this.pin});
  final String pin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: EvcColors.ink,
        borderRadius: BorderRadius.circular(EvcRadius.sm),
      ),
      child: Column(
        children: [
          const Text('PIN',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          Text(pin,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
        ],
      ),
    );
  }
}

/// VAT-style receipt from the settled payment + trip facts.
class _Receipt extends ConsumerWidget {
  const _Receipt({required this.trip});
  final ActiveTrip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pay = ref.watch(tripPaymentProvider(trip.id)).value;
    final total = pay?.total ?? trip.fare;
    final vat = pay?.vat ?? (trip.vat ?? 0);
    final tip = pay?.tip ?? (trip.tip ?? 0);
    final amount = pay?.amount ?? trip.fare;
    final subtotal = amount - vat;
    final discount = trip.discount ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EvcColors.mist,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        border: Border.all(color: EvcColors.line),
      ),
      child: Column(
        children: [
          _row('Subtotal', 'AED ${subtotal.toStringAsFixed(2)}'),
          _row('VAT (5%)', 'AED ${vat.toStringAsFixed(2)}'),
          if (discount > 0)
            _row('Promo discount', '−AED ${discount.toStringAsFixed(2)}'),
          if (tip > 0) _row('Tip', 'AED ${tip.toStringAsFixed(2)}'),
          const Divider(height: 18),
          _row('Total', 'AED ${total.toStringAsFixed(2)}', bold: true),
          const SizedBox(height: 10),
          Row(
            children: [
              _tag(Icons.route, '${(trip.distanceKm ?? 0).toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              if (trip.durationMin != null)
                _tag(Icons.schedule, '${trip.durationMin} min'),
              const Spacer(),
              _tag(Icons.payments_outlined, _payLabel(pay?.type)),
            ],
          ),
          if (trip.co2SavedKg != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Co2Badge(kg: trip.co2SavedKg!, compact: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    fontSize: bold ? 16 : 14,
                    color: bold ? EvcColors.ink : EvcColors.slate)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 16 : 14)),
          ],
        ),
      );

  Widget _tag(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: EvcColors.slate),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EvcColors.slate)),
        ],
      );

  static String _payLabel(String? type) => switch (type) {
        'card' => 'Card',
        'apple_pay' => 'Apple Pay',
        'wallet' => 'Wallet',
        _ => 'Cash',
      };
}

class _RatingBar extends StatefulWidget {
  const _RatingBar({required this.onSubmit});
  final Future<void> Function(int stars, List<String> tags, num tip) onSubmit;

  @override
  State<_RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<_RatingBar> {
  static const _tagOptions = [
    'Great driving',
    'Clean car',
    'Friendly',
    'On time',
    'Felt safe',
  ];
  static const _tipOptions = <num>[0, 5, 10, 20];

  int _stars = 0;
  final Set<String> _tags = {};
  num _tip = 0;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    await widget.onSubmit(_stars, _tags.toList(), _tip);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate your driver',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return IconButton(
                onPressed: () => setState(() => _stars = i + 1),
                icon: Icon(filled ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF5A623), size: 34),
              );
            }),
          ),
        ),
        if (_stars > 0) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tagOptions)
                _choice(tag, _tags.contains(tag), () {
                  setState(() =>
                      _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag));
                }),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Add a tip (optional)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final amt in _tipOptions)
                _choice(amt == 0 ? 'No tip' : 'AED $amt', _tip == amt,
                    () => setState(() => _tip = amt)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(_tip > 0 ? 'Submit & tip AED $_tip' : 'Submit rating'),
          ),
        ],
      ],
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? EvcColors.primary : EvcColors.mist,
          borderRadius: BorderRadius.circular(EvcRadius.lg),
          border: Border.all(
              color: selected ? EvcColors.primary : EvcColors.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : EvcColors.ink)),
      ),
    );
  }
}
