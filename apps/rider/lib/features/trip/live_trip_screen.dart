import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/active_trip_provider.dart';
import '../../state/booking_controller.dart';

/// Live trip screen driven by the real `trips` row (Realtime).
/// Step 1: shows the created trip + its status with cancel. Driver card and
/// live tracking are enriched in later steps.
class LiveTripScreen extends ConsumerWidget {
  const LiveTripScreen({super.key, required this.tripId});

  final String tripId;

  Future<void> _cancel(BuildContext context) async {
    try {
      await EvcTrips.cancel(tripId);
    } catch (_) {/* ignore — leaving the screen anyway */}
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingControllerProvider);
    final tripAsync = ref.watch(tripStreamProvider(tripId));
    final trip = tripAsync.value;
    final status = trip?.status ?? LiveTripStatus.requested;

    return Scaffold(
      body: Stack(
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
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _StatusPill(status: status),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _Panel(
              trip: trip,
              status: status,
              onCancel: () => _cancel(context),
              onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
        ],
      ),
    );
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

class _Panel extends StatelessWidget {
  const _Panel({
    required this.trip,
    required this.status,
    required this.onCancel,
    required this.onDone,
  });

  final ActiveTrip? trip;
  final LiveTripStatus status;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final searching =
        status == LiveTripStatus.requested || status == LiveTripStatus.matched;
    final done =
        status == LiveTripStatus.completed || status == LiveTripStatus.canceled;

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
            children: [
              Row(
                children: [
                  if (searching)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: EvcColors.primary),
                    )
                  else
                    Icon(
                        status == LiveTripStatus.completed
                            ? Icons.check_circle
                            : Icons.directions_car_filled,
                        color: EvcColors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(_headline(status),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                trip == null
                    ? 'Creating your trip…'
                    : 'To ${trip!.destName}  ·  ${(trip!.distanceKm ?? 0).toStringAsFixed(1)} km',
                style: const TextStyle(color: EvcColors.slate),
              ),
              if (trip != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip('AED ${trip!.fare.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    if (trip!.pin != null) _chip('PIN ${trip!.pin}'),
                    const Spacer(),
                    if (trip!.co2SavedKg != null)
                      Co2Badge(kg: trip!.co2SavedKg!, compact: true),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (done)
                FilledButton(onPressed: onDone, child: const Text('Done'))
              else
                OutlinedButton(
                    onPressed: onCancel, child: const Text('Cancel ride')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: EvcColors.mist,
          borderRadius: BorderRadius.circular(EvcRadius.sm),
        ),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );
}
