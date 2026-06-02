import 'dart:async';

import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

/// Incoming ride-request card with a countdown. Pops `true` (accept) or
/// `false` (decline / timed out).
class RideRequestSheet extends StatefulWidget {
  const RideRequestSheet({super.key, required this.request});

  final RideRequest request;

  @override
  State<RideRequestSheet> createState() => _RideRequestSheetState();
}

class _RideRequestSheetState extends State<RideRequestSheet> {
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
        Navigator.of(context).pop(false);
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
    final r = widget.request;
    return Container(
      decoration: const BoxDecoration(
        color: EvcColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Countdown bar.
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
                  Text('New ride · ${r.tierName}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${_remaining}s',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: EvcColors.slate)),
                ],
              ),
              const SizedBox(height: 14),
              // Fare + rider.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: EvcColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(EvcRadius.sm),
                    ),
                    child: Text('AED ${r.fareAed.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: EvcColors.primaryDark)),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: r.rider.avatarColor,
                    child: Text(r.rider.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.rider.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 13, color: EvcColors.warning),
                            const SizedBox(width: 3),
                            Text('${r.rider.rating}',
                                style: const TextStyle(
                                    color: EvcColors.slate, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _leg(Icons.my_location, '${r.pickupMinutes} min to pickup',
                  r.pickup.name, EvcColors.primary),
              const Padding(
                padding: EdgeInsets.only(left: 11),
                child: SizedBox(height: 18, child: VerticalDivider(width: 2)),
              ),
              _leg(
                  Icons.location_on,
                  '${r.tripMinutes} min · ${r.distanceKm} km trip',
                  r.destination.name,
                  EvcColors.ink),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Accept'),
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

  Widget _leg(IconData icon, String label, String place, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: EvcColors.slate, fontSize: 12)),
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