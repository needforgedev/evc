import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

import '../mock/admin_mock.dart';

@immutable
class AdminState {
  const AdminState({required this.drivers, required this.trips});

  final List<DriverRecord> drivers;
  final List<AdminTrip> trips;

  List<DriverRecord> get pending =>
      drivers.where((d) => d.status == DriverAccountStatus.pending).toList();

  List<AdminTrip> get ongoing =>
      trips.where((t) => t.status == AdminTripStatus.ongoing).toList();

  AdminState copyWith({List<DriverRecord>? drivers, List<AdminTrip>? trips}) =>
      AdminState(drivers: drivers ?? this.drivers, trips: trips ?? this.trips);
}

/// Holds the admin's mutable view of drivers and trips so moderation actions
/// (approve / suspend / cancel) reflect immediately across screens.
class AdminController extends Notifier<AdminState> {
  @override
  AdminState build() => const AdminState(
        drivers: AdminMock.drivers,
        trips: AdminMock.trips,
      );

  void _setDriver(String name, DriverAccountStatus status) {
    state = state.copyWith(
      drivers: [
        for (final d in state.drivers)
          d.name == name ? d.copyWith(status: status) : d,
      ],
    );
  }

  void approveDriver(String name) =>
      _setDriver(name, DriverAccountStatus.active);

  void rejectDriver(String name) => state = state.copyWith(
        drivers: state.drivers.where((d) => d.name != name).toList(),
      );

  void suspendDriver(String name) =>
      _setDriver(name, DriverAccountStatus.suspended);

  void reactivateDriver(String name) =>
      _setDriver(name, DriverAccountStatus.active);

  void cancelTrip(String id) {
    state = state.copyWith(
      trips: [
        for (final t in state.trips)
          t.id == id
              ? t.copyWith(
                  status: AdminTripStatus.canceled, stageLabel: 'Canceled by ops')
              : t,
      ],
    );
  }
}

final adminControllerProvider =
    NotifierProvider<AdminController, AdminState>(AdminController.new);