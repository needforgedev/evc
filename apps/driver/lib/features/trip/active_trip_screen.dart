import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../l10n/app_strings.dart';
import '../../state/driver_account.dart';
import '../../state/driver_data.dart';
import '../../state/driver_job_provider.dart';
import '../../state/route_provider.dart';

/// Pull a clean message out of a thrown error (e.g. a PostgrestException) so the
/// driver sees "This ride request has expired" instead of the raw exception.
String _cleanError(Object e) {
  final m = RegExp(r'message: ([^,]+?)(?:,|\))').firstMatch(e.toString());
  return m?.group(1)?.trim() ?? e.toString();
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

  // Live-location publisher (#8). While driving a trip, push the driver's
  // position every couple of seconds so the rider sees the car move.
  Timer? _gpsTimer;
  LatLng? _simPos;

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  /// Start the publisher once a trip is active.
  void _ensurePublisher() {
    _gpsTimer ??=
        Timer.periodic(const Duration(seconds: 2), (_) => _publishTick());
  }

  Future<void> _publishTick() async {
    final job = ref.read(driverJobProvider).value;
    if (job == null) return;
    const driving = {
      LiveTripStatus.enroute,
      LiveTripStatus.arrived,
      LiveTripStatus.ongoing,
    };
    if (!driving.contains(job.status)) return; // only publish while driving

    final pickup = LatLng(job.pickupLat ?? 25.18, job.pickupLng ?? 55.25);
    final dest = LatLng(job.destLat ?? 25.18, job.destLng ?? 55.25);

    LatLng pos;
    if (EvcConfig.simulateDriverGps) {
      // Start a little "behind" the pickup, glide to the pickup while enroute,
      // then on to the destination once ongoing.
      _simPos ??= LatLng(pickup.latitude + (pickup.latitude - dest.latitude) * 0.3,
          pickup.longitude + (pickup.longitude - dest.longitude) * 0.3);
      final target = job.status == LiveTripStatus.ongoing ? dest : pickup;
      _simPos = LatLng(
        _simPos!.latitude + (target.latitude - _simPos!.latitude) * 0.12,
        _simPos!.longitude + (target.longitude - _simPos!.longitude) * 0.12,
      );
      pos = _simPos!;
    } else {
      pos = await EvcLocation.current(); // real device GPS (UAE fallback)
    }
    try {
      await EvcTrips.publishLocation(pos.latitude, pos.longitude);
    } catch (_) {/* best-effort */}
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_cleanError(e))));
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
      // Now free — pick up any request that was waiting for an available car.
      await EvcTrips.requeueWaiting();
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
      _gpsTimer?.cancel();
      return _SummaryView(trip: _completed!);
    }

    final job = ref.watch(driverJobProvider).value;
    if (job == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _ensurePublisher();

    final pLat = job.pickupLat ?? 25.18, pLng = job.pickupLng ?? 55.25;
    final dLat = job.destLat ?? 25.18, dLng = job.destLng ?? 55.25;
    final road = ref
        .watch(routeProvider(
            (oLat: pLat, oLng: pLng, dLat: dLat, dLng: dLng)))
        .value;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: EvcGoogleMap(
              center: LatLng(pLat, pLng),
              route: road?.points ?? const [],
              markers: [
                EvcMarker(
                    id: 'pickup',
                    position: LatLng(pLat, pLng),
                    title: job.pickupName,
                    hue: EvcMarkerHue.green),
                EvcMarker(
                    id: 'dest',
                    position: LatLng(dLat, dLng),
                    title: job.destName,
                    hue: EvcMarkerHue.red),
              ],
            ),
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
                    onTimeout: () => _run(() => EvcTrips.passRide(job.id)),
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

/// Incoming offer with a 30s countdown. Letting it lapse is a *soft pass*
/// ([onTimeout]) — the request rolls to the next driver but can come back to
/// this one on a later round; tapping Decline is a *hard no* ([onDecline]).
class _OfferCard extends StatefulWidget {
  const _OfferCard({
    required this.trip,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onTimeout,
  });

  final ActiveTrip trip;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTimeout;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  static const _seconds = 30;
  int _remaining = _seconds;
  Timer? _timer;
  bool _acted = false; // guards against accept/decline racing the timer

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _timeout();
    });
  }

  /// Window lapsed with no action → soft pass (re-offerable next round).
  void _timeout() {
    if (_acted) return;
    _acted = true;
    _timer?.cancel();
    widget.onTimeout();
  }

  /// Stop the countdown the instant the driver acts, so the auto-decline can't
  /// fire mid-accept and un-match the trip (which caused the accept error).
  void _accept() {
    if (_acted) return;
    _acted = true;
    _timer?.cancel();
    widget.onAccept();
  }

  void _decline() {
    if (_acted) return;
    _acted = true;
    _timer?.cancel();
    widget.onDecline();
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
              Text(AppStrings.of(context).newRideRequest,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
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
          _leg(Icons.my_location, AppStrings.of(context).pickUp, t.pickupName,
              EvcColors.primary),
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
              child: Text(
                  AppStrings.of(context)
                      .youEarn('AED ${t.fare.toStringAsFixed(2)}'),
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
                  onPressed: widget.busy ? null : _decline,
                  child: Text(AppStrings.of(context).decline),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: widget.busy ? null : _accept,
                  child: Text(AppStrings.of(context).accept),
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
    final tr = AppStrings.of(context);
    final (target, label) = trip.status == LiveTripStatus.ongoing
        ? (trip.destName, tr.dropOff)
        : (trip.pickupName, tr.pickUp);

    final (cta, action) = switch (trip.status) {
      LiveTripStatus.arrived => (tr.startTrip, onStart),
      LiveTripStatus.ongoing => (tr.completeTrip, onComplete),
      _ => (tr.iveArrived, onArrived),
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
                  Center(
                      child: Text(AppStrings.of(context).youEarned,
                          style: const TextStyle(color: EvcColors.slate))),
                  Center(
                    child: Text('AED ${earned.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 38, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 20),
                  Text(AppStrings.of(context).rateYourRider,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
              child: FilledButton(
                  onPressed: _done, child: Text(AppStrings.of(context).done)),
            ),
          ],
        ),
      ),
    );
  }
}
