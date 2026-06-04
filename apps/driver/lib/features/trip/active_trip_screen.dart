import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/driver_account.dart';
import '../../state/driver_data.dart';
import '../../state/driver_job_provider.dart';

Place _place(String name, double? lat, double? lng) {
  final la = lat ?? 25.18, ln = lng ?? 55.25;
  return Place(
    name: name,
    address: '',
    lat: la,
    lng: ln,
    mapX: (((ln - 55.10) / 0.30).clamp(0.05, 0.95)).toDouble(),
    mapY: (((25.30 - la) / 0.30).clamp(0.05, 0.95)).toDouble(),
  );
}

/// The driver's live job: incoming offer → accept/decline → enroute → arrived →
/// ongoing → complete. Driven by [driverJobProvider] (realtime).
class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  bool _busy = false;
  ActiveTrip? _completed; // set once the trip finishes → shows summary

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(ActiveTrip trip) async {
    setState(() => _busy = true);
    try {
      final done = await EvcTrips.completeTrip(trip.id);
      ref.invalidate(driverEarningsProvider);
      ref.invalidate(currentDriverProvider);
      if (mounted) setState(() => _completed = done);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(driverJobProvider, (prev, next) {
      // Offer expired / declined / canceled → leave the screen.
      if (next.value == null && _completed == null && mounted) {
        Navigator.of(context).maybePop();
      }
    });

    if (_completed != null) {
      return _SummaryView(trip: _completed!);
    }

    final job = ref.watch(driverJobProvider).value;
    if (job == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pickup = _place(job.pickupName, job.pickupLat, job.pickupLng);
    final dest = _place(job.destName, job.destLat, job.destLng);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PlaceholderMap(
                pickup: pickup, destination: dest, showRoute: true),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _pill(job.status.name),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: job.status == LiveTripStatus.matched
                ? _OfferCard(
                    trip: job,
                    busy: _busy,
                    onAccept: () => _run(() => EvcTrips.acceptRide(job.id)),
                    onDecline: () => _run(() => EvcTrips.declineRide(job.id)),
                  )
                : _DrivePanel(
                    trip: job,
                    busy: _busy,
                    onArrived: () => _run(() =>
                        EvcTrips.advanceTrip(job.id, LiveTripStatus.arrived)),
                    onStart: () => _run(() =>
                        EvcTrips.advanceTrip(job.id, LiveTripStatus.ongoing)),
                    onComplete: () => _complete(job),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: EvcColors.ink,
          borderRadius: BorderRadius.circular(EvcRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.navigation, color: EvcColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), child: child),
      ),
    );
  }
}

class _RiderLine extends ConsumerWidget {
  const _RiderLine({required this.riderId});
  final String? riderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = riderId == null
        ? null
        : ref.watch(riderProfileProvider(riderId!)).value;
    final name = (p?['full_name'] as String?) ?? 'Rider';
    final rating = (p?['rating'] as num?)?.toStringAsFixed(2) ?? '5.0';
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: EvcColors.ink,
          child: Text(name.isEmpty ? 'R' : name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              Row(children: [
                const Icon(Icons.star, size: 14, color: EvcColors.warning),
                const SizedBox(width: 3),
                Text(rating,
                    style: const TextStyle(
                        color: EvcColors.slate, fontSize: 13)),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

/// Incoming offer with a 15s countdown that auto-declines.
class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.trip,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ActiveTrip trip;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  static const _seconds = 15;
  int _remaining = _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _remaining / _seconds,
              minHeight: 6,
              backgroundColor: EvcColors.line,
              color: EvcColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('New ride request',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const Spacer(),
              Text('${_remaining}s',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: EvcColors.slate)),
            ],
          ),
          const SizedBox(height: 12),
          _RiderLine(riderId: t.riderId),
          const SizedBox(height: 12),
          _leg(Icons.my_location, 'Pickup', t.pickupName, EvcColors.primary),
          const SizedBox(height: 6),
          _leg(Icons.location_on, '${(t.distanceKm ?? 0).toStringAsFixed(1)} km',
              t.destName, EvcColors.ink),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: EvcColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(EvcRadius.sm),
              ),
              child: Text('You earn AED ${t.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: EvcColors.primaryDark)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.busy ? null : widget.onDecline,
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: widget.busy ? null : widget.onAccept,
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leg(IconData icon, String label, String place, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: EvcColors.slate, fontSize: 12)),
              Text(place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrivePanel extends StatelessWidget {
  const _DrivePanel({
    required this.trip,
    required this.busy,
    required this.onArrived,
    required this.onStart,
    required this.onComplete,
  });

  final ActiveTrip trip;
  final bool busy;
  final VoidCallback onArrived;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final (target, label) = trip.status == LiveTripStatus.ongoing
        ? (trip.destName, 'Drop-off')
        : (trip.pickupName, 'Pick-up');

    final (cta, action) = switch (trip.status) {
      LiveTripStatus.arrived => ('Start trip', onStart),
      LiveTripStatus.ongoing => ('Complete trip', onComplete),
      _ => ("I've arrived", onArrived),
    };

    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.turn_right, color: EvcColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: EvcColors.slate, fontSize: 12)),
                    Text(target,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              if (trip.status == LiveTripStatus.arrived && trip.pin != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EvcColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('PIN ${trip.pin}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                ),
            ],
          ),
          const Divider(height: 24),
          _RiderLine(riderId: trip.riderId),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : action,
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(cta),
          ),
        ],
      ),
    );
  }
}

class _SummaryView extends ConsumerStatefulWidget {
  const _SummaryView({required this.trip});
  final ActiveTrip trip;

  @override
  ConsumerState<_SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends ConsumerState<_SummaryView> {
  int _stars = 5;

  Future<void> _done() async {
    final t = widget.trip;
    if (t.riderId != null) {
      try {
        await EvcTrips.rate(t.id, t.riderId!, _stars);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final fare = widget.trip.fare;
    final earned = fare * 0.85; // after 15% EVC fee

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: EvcColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: EvcColors.primaryDark, size: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                      child: Text('You earned',
                          style: TextStyle(color: EvcColors.slate))),
                  Center(
                    child: Text('AED ${earned.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 38, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Rate your rider',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final on = i < _stars;
                      return IconButton(
                        iconSize: 38,
                        onPressed: () => setState(() => _stars = i + 1),
                        icon: Icon(
                            on
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: on ? EvcColors.warning : EvcColors.line),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: FilledButton(onPressed: _done, child: const Text('Done')),
            ),
          ],
        ),
      ),
    );
  }
}
