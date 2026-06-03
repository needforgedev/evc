import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// Data accumulated across rider onboarding (phone → name → OTP).
@immutable
class OnboardingDraft {
  const OnboardingDraft({this.phone = '', this.fullName = '', this.email = ''});

  final String phone;
  final String fullName;
  final String email;

  OnboardingDraft copyWith({String? phone, String? fullName, String? email}) =>
      OnboardingDraft(
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
      );
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void setPhone(String phone) => state = state.copyWith(phone: phone);

  void setDetails({required String fullName, required String email}) =>
      state = state.copyWith(fullName: fullName, email: email);

  /// Registers the rider against Supabase (or no-ops in mock mode).
  Future<void> submit() {
    final d = state;
    return RiderRegistration.register(RiderRegistrationData(
      phone: d.phone,
      fullName: d.fullName,
      email: d.email,
    ));
  }

  void reset() => state = const OnboardingDraft();
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
        OnboardingController.new);
