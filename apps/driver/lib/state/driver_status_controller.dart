import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DriverStatus { offline, online, charging }

@immutable
class DriverState {
  const DriverState({
    this.status = DriverStatus.offline,
    this.batteryPercent = 78,
    this.rangeKm = 312,
  });

  final DriverStatus status;
  final int batteryPercent;
  final int rangeKm;

  bool get isOnline => status == DriverStatus.online;
  bool get isCharging => status == DriverStatus.charging;

  DriverState copyWith({DriverStatus? status, int? batteryPercent, int? rangeKm}) {
    return DriverState(
      status: status ?? this.status,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      rangeKm: rangeKm ?? this.rangeKm,
    );
  }
}

/// Tracks whether the driver is offline / online / charging, plus battery+range.
class DriverStatusController extends Notifier<DriverState> {
  @override
  DriverState build() => const DriverState();

  void goOnline() => state = state.copyWith(status: DriverStatus.online);
  void goOffline() => state = state.copyWith(status: DriverStatus.offline);

  /// "I'm charging" — auto goes offline for dispatch while plugged in.
  void startCharging() => state = state.copyWith(status: DriverStatus.charging);

  void stopCharging() => state = state.copyWith(
        status: DriverStatus.offline,
        batteryPercent: 96,
        rangeKm: 384,
      );
}

final driverStatusProvider =
    NotifierProvider<DriverStatusController, DriverState>(
        DriverStatusController.new);