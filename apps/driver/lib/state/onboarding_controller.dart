import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// Data accumulated across the driver onboarding steps
/// (phone → details → OTP). Documents are uploaded separately, after sign-up.
@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.phone = '',
    this.fullName = '',
    this.email = '',
    this.vehicleModel = '',
    this.plate = '',
    this.ownership = OwnershipType.driver,
    this.batteryPercent = 80,
    this.rangeKm = 320,
  });

  final String phone;
  final String fullName;
  final String email;
  final String vehicleModel;
  final String plate;
  final OwnershipType ownership;
  final int batteryPercent;
  final int rangeKm;

  OnboardingDraft copyWith({
    String? phone,
    String? fullName,
    String? email,
    String? vehicleModel,
    String? plate,
    OwnershipType? ownership,
    int? batteryPercent,
    int? rangeKm,
  }) {
    return OnboardingDraft(
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      plate: plate ?? this.plate,
      ownership: ownership ?? this.ownership,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      rangeKm: rangeKm ?? this.rangeKm,
    );
  }
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void setPhone(String phone) => state = state.copyWith(phone: phone);

  void setDetails({
    required String fullName,
    required String email,
    required String vehicleModel,
    required String plate,
    required OwnershipType ownership,
    required int batteryPercent,
    required int rangeKm,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      vehicleModel: vehicleModel,
      plate: plate,
      ownership: ownership,
      batteryPercent: batteryPercent,
      rangeKm: rangeKm,
    );
  }

  /// Persists the driver to Supabase (or no-ops in mock mode). Throws
  /// [RegistrationException] on failure.
  Future<void> submit() {
    final d = state;
    return DriverRegistration.register(DriverRegistrationData(
      phone: d.phone,
      fullName: d.fullName,
      email: d.email,
      vehicleModel: d.vehicleModel,
      plate: d.plate,
      ownership: d.ownership,
      batteryPercent: d.batteryPercent,
      rangeKm: d.rangeKm,
    ));
  }

  void reset() => state = const OnboardingDraft();
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
        OnboardingController.new);
