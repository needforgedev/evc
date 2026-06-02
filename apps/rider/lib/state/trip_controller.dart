import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

import '../mock/mock_data.dart';

@immutable
class TripState {
  const TripState({
    this.stage = TripStage.idle,
    this.driver,
    this.etaMinutes = 0,
  });

  final TripStage stage;
  final DriverProfile? driver;

  /// Minutes shown on the tracking screen (to pickup, then to destination).
  final int etaMinutes;

  TripState copyWith({TripStage? stage, DriverProfile? driver, int? etaMinutes}) {
    return TripState(
      stage: stage ?? this.stage,
      driver: driver ?? this.driver,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }
}

/// Simulates a trip's lifecycle with timers so the mock plays out on its own:
/// searching → driver en route → arrived → in progress → completed.
/// [skipToArrival] / [completeNow] let an impatient demo jump ahead.
class TripController extends Notifier<TripState> {
  final List<Timer> _timers = [];

  @override
  TripState build() {
    ref.onDispose(_cancelTimers);
    return const TripState();
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _at(int ms, VoidCallback fn) =>
      _timers.add(Timer(Duration(milliseconds: ms), fn));

  /// Begin the simulated dispatch.
  void start() {
    _cancelTimers();
    state = const TripState(stage: TripStage.searching);
    _at(2500, () => state = state.copyWith(
          stage: TripStage.enRouteToPickup,
          driver: MockData.driver,
          etaMinutes: 3,
        ));
    _at(7500, () => state = state.copyWith(stage: TripStage.arrived, etaMinutes: 0));
    _at(10500, () => state = state.copyWith(
          stage: TripStage.inProgress,
          etaMinutes: 14,
        ));
    _at(16500, () => state = state.copyWith(stage: TripStage.completed, etaMinutes: 0));
  }

  /// Jump straight to the driver arriving (skip searching/approach).
  void skipToArrival() {
    _cancelTimers();
    state = state.copyWith(
      stage: TripStage.arrived,
      driver: MockData.driver,
      etaMinutes: 0,
    );
    _at(2500, () => state = state.copyWith(
          stage: TripStage.inProgress,
          etaMinutes: 14,
        ));
    _at(7000, () => state = state.copyWith(stage: TripStage.completed, etaMinutes: 0));
  }

  /// End the trip immediately.
  void completeNow() {
    _cancelTimers();
    state = state.copyWith(
      stage: TripStage.completed,
      driver: state.driver ?? MockData.driver,
      etaMinutes: 0,
    );
  }

  void reset() {
    _cancelTimers();
    state = const TripState();
  }
}

final tripControllerProvider =
    NotifierProvider<TripController, TripState>(TripController.new);