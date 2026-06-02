import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

import '../mock/mock_data.dart';

@immutable
class JobState {
  const JobState({this.stage = JobStage.none, this.request});

  final JobStage stage;
  final RideRequest? request;

  JobState copyWith({JobStage? stage, RideRequest? request}) =>
      JobState(stage: stage ?? this.stage, request: request ?? this.request);
}

/// Drives the driver's job: an offer arrives after going online, then the
/// accepted trip moves enRouteToPickup → arrived → inProgress → completed.
class JobController extends Notifier<JobState> {
  Timer? _offerTimer;

  @override
  JobState build() {
    ref.onDispose(() => _offerTimer?.cancel());
    return const JobState();
  }

  /// Called when the driver goes online — surface a request shortly after.
  void lookForRide() {
    _offerTimer?.cancel();
    _offerTimer = Timer(const Duration(milliseconds: 3200), () {
      if (state.stage == JobStage.none) {
        state = const JobState(stage: JobStage.offered, request: DriverMock.offer);
      }
    });
  }

  void accept() => state = state.copyWith(stage: JobStage.enRouteToPickup);

  void decline() {
    state = const JobState();
    lookForRide();
  }

  void markArrived() => state = state.copyWith(stage: JobStage.arrived);
  void startTrip() => state = state.copyWith(stage: JobStage.inProgress);
  void completeTrip() => state = state.copyWith(stage: JobStage.completed);

  /// Clear the finished job, ready for the next request.
  void clear() {
    _offerTimer?.cancel();
    state = const JobState();
  }
}

final jobControllerProvider =
    NotifierProvider<JobController, JobState>(JobController.new);