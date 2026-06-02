import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/booking_controller.dart';
import '../../state/trip_controller.dart';
import 'package:evc_maps/evc_maps.dart';

import '../payment/payment_screen.dart';
import 'widgets/driver_card.dart';

/// Live trip screen. Reacts to [TripStage] from [tripControllerProvider]:
/// searching → driver en route → arrived → in progress → completed.
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _carAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void dispose() {
    _carAnim.dispose();
    super.dispose();
  }

  void _onStageChanged(TripStage stage) {
    if (stage == TripStage.inProgress) {
      _carAnim.forward(from: 0);
    } else if (stage == TripStage.completed) {
      _carAnim.value = 1;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaymentScreen()),
      );
    }
  }

  double? _carProgress(TripStage stage) => switch (stage) {
        TripStage.searching || TripStage.idle => null,
        TripStage.enRouteToPickup || TripStage.arrived => 0.0,
        TripStage.inProgress => _carAnim.value,
        TripStage.completed => 1.0,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(tripControllerProvider, (prev, next) {
      if (prev?.stage != next.stage) _onStageChanged(next.stage);
    });

    final booking = ref.watch(bookingControllerProvider);
    final trip = ref.watch(tripControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Map fills the screen; bottom panel overlays it.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _carAnim,
              builder: (context, _) => PlaceholderMap(
                pickup: booking.pickup,
                destination: booking.destination,
                showRoute: true,
                carProgress: _carProgress(trip.stage),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _StatusPill(stage: trip.stage, eta: trip.etaMinutes),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: trip.stage == TripStage.searching
                ? _SearchingPanel(
                    destination: booking.destination?.name ?? '',
                    onCancel: _cancel,
                  )
                : (trip.driver != null
                    ? DriverCard(
                        driver: trip.driver!,
                        stage: trip.stage,
                        onSkip: _advance,
                        onCancel: _cancel,
                      )
                    : const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  void _advance() {
    final stage = ref.read(tripControllerProvider).stage;
    final notifier = ref.read(tripControllerProvider.notifier);
    if (stage == TripStage.enRouteToPickup) {
      notifier.skipToArrival();
    } else {
      notifier.completeNow();
    }
  }

  void _cancel() {
    ref.read(tripControllerProvider.notifier).reset();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.stage, required this.eta});

  final TripStage stage;
  final int eta;

  @override
  Widget build(BuildContext context) {
    final text = eta > 0 ? '${stage.headline}  ·  $eta min' : stage.headline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EvcColors.ink,
        borderRadius: BorderRadius.circular(EvcRadius.lg),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: EvcColors.primary, size: 18),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SearchingPanel extends StatelessWidget {
  const _SearchingPanel({required this.destination, required this.onCancel});

  final String destination;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: EvcColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finding your EV…',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text('Matching you with a nearby electric car',
                        style: TextStyle(color: EvcColors.slate, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

/// Shared rounded bottom sheet container.
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: child,
        ),
      ),
    );
  }
}