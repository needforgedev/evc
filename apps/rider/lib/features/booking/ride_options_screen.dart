import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import 'package:evc_maps/evc_maps.dart';

import '../../mock/mock_data.dart';
import '../../state/booking_controller.dart';
import '../../state/pricing_provider.dart';
import '../trip/live_trip_screen.dart';

/// Choose a ride tier + payment, see the upfront fare, and confirm.
class RideOptionsScreen extends ConsumerWidget {
  const RideOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);
    final data = ref.watch(pricingDataProvider).value;

    // Real distance pickup→destination (same coords the server will price on).
    final dest = booking.destination;
    final distanceKm = dest == null
        ? 0.0
        : EvcPricing.haversineKm(
            booking.pickup.lat, booking.pickup.lng, dest.lat, dest.lng);

    // Priced tiers from the real `pricing`/`ride_tiers` tables (fallback to
    // mock while the config loads), cheapest first so the default tier is on top.
    final tiers = <RideTier>[
      if (data == null || data.tiers.isEmpty)
        ...MockData.tiers
      else
        for (final t in data.tiers)
          _toRideTier(
              t,
              EvcPricing.estimate(
                  distanceKm: distanceKm,
                  multiplier: t.multiplier,
                  p: data.pricing)),
    ]..sort((a, b) => a.fareAed.compareTo(b.fareAed));
    final selected = tiers.firstWhere((t) => t.id == booking.effectiveTier.id,
        orElse: () => tiers.first);
    final route = data == null
        ? null
        : EvcPricing.estimate(
            distanceKm: distanceKm, multiplier: 1, p: data.pricing);

    return Scaffold(
      body: Column(
        children: [
          // Map with the route.
          SizedBox(
            // Full width — without this the Stack collapses to the back
            // button's width and the map renders as a narrow centre strip.
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.30,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PlaceholderMap(
                    pickup: booking.pickup,
                    destination: booking.destination,
                    showRoute: true,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: EvcColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EvcColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _routeSummary(context, booking, route),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        for (final tier in tiers)
                          _TierTile(
                            tier: tier,
                            selected: tier.id == selected.id,
                            onTap: () => controller.setTier(tier),
                          ),
                      ],
                    ),
                  ),
                  _footer(context, ref, booking, selected),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeSummary(
      BuildContext context, BookingState booking, FareEstimate? route) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.destination?.name ?? 'Destination',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  'From ${booking.pickup.address}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: EvcColors.slate, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EvcColors.mist,
              borderRadius: BorderRadius.circular(EvcRadius.sm),
            ),
            child: Column(
              children: [
                Text(route == null ? '—' : '${route.durationMin} min',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    route == null
                        ? ''
                        : '${route.distanceKm.toStringAsFixed(1)} km',
                    style:
                        const TextStyle(color: EvcColors.slate, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, WidgetRef ref, BookingState booking,
      RideTier selected) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: EvcColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            children: [
              InkWell(
                onTap: () => _pickPayment(context, ref),
                borderRadius: BorderRadius.circular(EvcRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(booking.payment.icon, color: EvcColors.ink),
                      const SizedBox(width: 12),
                      Text(booking.payment.label,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Text(booking.payment.detail,
                          style: const TextStyle(color: EvcColors.slate)),
                      const Spacer(),
                      const Text('Change',
                          style: TextStyle(
                              color: EvcColors.primaryDark,
                              fontWeight: FontWeight.w700)),
                      const Icon(Icons.keyboard_arrow_down,
                          color: EvcColors.primaryDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _PromoRow(
                applied: booking.promoDiscount > 0,
                label: booking.promoLabel,
                discount: booking.promoDiscount,
                onApply: (code) async {
                  if (code.trim().isEmpty) return;
                  try {
                    final res = await EvcTrips.validatePromo(
                        code.trim(), selected.fareAed);
                    if (res.valid && res.discount > 0) {
                      ref.read(bookingControllerProvider.notifier).setPromo(
                          code.trim().toUpperCase(),
                          res.discount,
                          res.description);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Invalid or expired promo code.')));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Could not check promo code.')));
                    }
                  }
                },
                onRemove: () =>
                    ref.read(bookingControllerProvider.notifier).clearPromo(),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => _confirm(context, ref, booking),
                child: Text(_confirmLabel(selected, booking.promoDiscount)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, BookingState booking) async {
    final dest = booking.destination;
    if (dest == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final trip = await EvcTrips.requestRide(
        tierId: booking.effectiveTier.id,
        pickupName: booking.pickup.name,
        pickupAddress: booking.pickup.address,
        pickupLat: booking.pickup.lat,
        pickupLng: booking.pickup.lng,
        destName: dest.name,
        destAddress: dest.address,
        destLat: dest.lat,
        destLng: dest.lng,
        paymentType: booking.payment.type,
        promoCode: booking.promoCode,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LiveTripScreen(tripId: trip.id)),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not request ride: $e')));
    }
  }

  void _pickPayment(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EvcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final current = ref.read(bookingControllerProvider).payment;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Payment method',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              for (final m in MockData.paymentMethods)
                ListTile(
                  leading: Icon(m.icon, color: EvcColors.ink),
                  title: Text(m.label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(m.detail),
                  trailing: m.type == current.type
                      ? const Icon(Icons.check_circle,
                          color: EvcColors.primary)
                      : null,
                  onTap: () {
                    ref.read(bookingControllerProvider.notifier).setPayment(m);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Build the display model the UI/controller use from a DB tier + its estimate.
RideTier _toRideTier(RideTierConfig t, FareEstimate e) => RideTier(
      id: t.id,
      name: t.name,
      blurb: t.blurb,
      seats: t.seats,
      fareAed: e.fare,
      etaMinutes: e.durationMin,
      co2SavedKg: e.co2Kg,
      icon: _tierIcon(t.id),
    );

IconData _tierIcon(String id) => switch (id) {
      'comfort' => Icons.airline_seat_recline_extra,
      'xl' => Icons.airport_shuttle,
      'premium' => Icons.workspace_premium,
      _ => Icons.directions_car_filled,
    };

String _confirmLabel(RideTier t, double discount) {
  final net = (t.fareAed - discount).clamp(0.0, double.infinity);
  return 'Confirm ${t.name}  ·  AED ${net.toStringAsFixed(2)}';
}

/// Promo-code entry / applied state shown above the confirm button.
class _PromoRow extends StatefulWidget {
  const _PromoRow({
    required this.applied,
    required this.label,
    required this.discount,
    required this.onApply,
    required this.onRemove,
  });

  final bool applied;
  final String? label;
  final double discount;
  final Future<void> Function(String code) onApply;
  final VoidCallback onRemove;

  @override
  State<_PromoRow> createState() => _PromoRowState();
}

class _PromoRowState extends State<_PromoRow> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    await widget.onApply(_controller.text);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.applied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: EvcColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(EvcRadius.sm),
          border: Border.all(color: EvcColors.primary),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, size: 18, color: EvcColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  '${widget.label ?? 'Promo'} · −AED ${widget.discount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            InkWell(
              onTap: widget.onRemove,
              child: const Icon(Icons.close, size: 18, color: EvcColors.slate),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Promo code',
                prefixIcon: Icon(Icons.local_offer_outlined),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _busy ? null : _apply,
          // Bounded size — the app theme defaults buttons to full width
          // (infinite min-width), which can't live in a Row.
          style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2))
              : const Text('Apply'),
        ),
      ],
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.tier,
    required this.selected,
    required this.onTap,
  });

  final RideTier tier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EvcRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? EvcColors.primary.withValues(alpha: 0.06)
                : EvcColors.surface,
            borderRadius: BorderRadius.circular(EvcRadius.md),
            border: Border.all(
              color: selected ? EvcColors.primary : EvcColors.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: EvcColors.mist,
                  borderRadius: BorderRadius.circular(EvcRadius.sm),
                ),
                child: Icon(tier.icon, color: EvcColors.ink, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(tier.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(width: 6),
                        Icon(Icons.person, size: 14, color: EvcColors.slate),
                        Text('${tier.seats}',
                            style: const TextStyle(
                                color: EvcColors.slate, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(tier.blurb,
                        style: const TextStyle(
                            color: EvcColors.slate, fontSize: 13)),
                    if (selected) ...[
                      const SizedBox(height: 8),
                      Co2Badge(kg: tier.co2SavedKg, compact: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('AED ${tier.fareAed.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${tier.etaMinutes} min trip',
                      style: const TextStyle(
                          color: EvcColors.slate, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}