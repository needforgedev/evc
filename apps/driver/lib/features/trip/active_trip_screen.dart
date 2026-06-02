import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_maps/evc_maps.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

import '../../state/job_controller.dart';
import 'trip_summary_screen.dart';

/// The trip the driver is fulfilling: navigate to pickup → arrive → start →
/// complete, driven by [jobControllerProvider].
class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen>
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

  void _onStage(JobStage stage) {
    if (stage == JobStage.inProgress) {
      _carAnim.forward(from: 0);
    } else if (stage == JobStage.completed) {
      _carAnim.value = 1;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TripSummaryScreen()),
      );
    }
  }

  double? _carProgress(JobStage stage) => switch (stage) {
        JobStage.inProgress => _carAnim.value,
        JobStage.completed => 1.0,
        _ => 0.0,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(jobControllerProvider, (prev, next) {
      if (prev?.stage != next.stage) _onStage(next.stage);
    });

    final job = ref.watch(jobControllerProvider);
    final request = job.request;
    if (request == null) return const SizedBox.shrink();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _carAnim,
              builder: (context, _) => PlaceholderMap(
                pickup: request.pickup,
                destination: request.destination,
                showRoute: true,
                carProgress: _carProgress(job.stage),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _StatusPill(stage: job.stage),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _TripPanel(request: request, stage: job.stage),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.stage});
  final JobStage stage;

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
          const Icon(Icons.navigation, color: EvcColors.primary, size: 18),
          const SizedBox(width: 6),
          Text(stage.headline,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TripPanel extends ConsumerWidget {
  const _TripPanel({required this.request, required this.stage});

  final RideRequest request;
  final JobStage stage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.read(jobControllerProvider.notifier);
    final target =
        stage == JobStage.inProgress ? request.destination : request.pickup;

    final (cta, action) = switch (stage) {
      JobStage.arrived => ('Start trip', job.startTrip),
      JobStage.inProgress => ('Complete trip', job.completeTrip),
      _ => ("I've arrived", job.markArrived),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation target.
              Row(
                children: [
                  const Icon(Icons.turn_right, color: EvcColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            stage == JobStage.inProgress
                                ? 'Drop-off'
                                : 'Pick-up',
                            style: const TextStyle(
                                color: EvcColors.slate, fontSize: 12)),
                        Text(target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  ),
                  if (stage == JobStage.arrived)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: EvcColors.ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PIN 4827',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                    ),
                ],
              ),
              const Divider(height: 24),
              // Rider row.
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: request.rider.avatarColor,
                    child: Text(request.rider.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.rider.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: EvcColors.warning),
                            const SizedBox(width: 3),
                            Text('${request.rider.rating}',
                                style: const TextStyle(
                                    color: EvcColors.slate, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _round(Icons.call),
                  const SizedBox(width: 8),
                  _round(Icons.chat_bubble_outline),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: action, child: Text(cta)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _round(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: EvcColors.mist,
        shape: BoxShape.circle,
        border: Border.all(color: EvcColors.line),
      ),
      child: Icon(icon, size: 20, color: EvcColors.ink),
    );
  }
}