import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/evc_config.dart';
import '../supabase/evc_supabase.dart';

class RegistrationException implements Exception {
  RegistrationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Shared dev-OTP sign-in used by both Rider and Driver registration.
///
/// Any phone + the fixed dev code is accepted; under the hood we sign up / sign
/// in with a deterministic, role-scoped email + password so we still get a real
/// Supabase session (JWT + RLS). Rider and Driver use different email domains,
/// so the same phone number can hold both a rider and a driver account.
abstract final class EvcDevAuth {
  static const String _devPassword = 'evc-dev-7464';

  static String emailForPhone(String role, String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final domain = switch (role) {
      'driver' => 'evc-driver.test',
      'rider' => 'evc-rider.test',
      _ => 'evc.test',
    };
    return '$digits@$domain';
  }

  /// Creates or signs into a role-scoped account. Returns the user id, or null
  /// in pure-mock mode (creds not configured) so flows still work offline.
  static Future<String?> signIn({
    required String role,
    required String phone,
    String? fullName,
    String? email,
  }) async {
    if (!EvcSupabase.isReady) return null;

    final client = EvcSupabase.client;
    final mail = emailForPhone(role, phone);
    try {
      await client.auth.signUp(
        email: mail,
        password: _devPassword,
        data: {'role': role, 'full_name': fullName, 'phone': phone},
      );
    } on AuthException {
      await client.auth
          .signInWithPassword(email: mail, password: _devPassword);
    }

    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw RegistrationException('Could not establish a session.');
    }
    return uid;
  }
}

/// Matches an entered code against the dev OTP (7464 by default).
bool verifyDevOtp(String code) =>
    EvcConfig.devMockOtp && code == EvcConfig.devOtpCode;
