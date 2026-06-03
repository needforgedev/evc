import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/evc_supabase.dart';
import 'dev_auth.dart';

/// Collected during rider onboarding (phone → name).
class RiderRegistrationData {
  const RiderRegistrationData({
    required this.phone,
    required this.fullName,
    this.email,
  });

  final String phone;
  final String fullName;
  final String? email;
}

/// Registers a rider: dev-OTP sign-in (role 'rider') + profile update. Riders
/// have no vehicle/docs/approval, so they're usable immediately. No-op in mock.
abstract final class RiderRegistration {
  static Future<void> register(RiderRegistrationData d) async {
    final uid = await EvcDevAuth.signIn(
      role: 'rider',
      phone: d.phone,
      fullName: d.fullName,
      email: d.email,
    );
    if (uid == null) return; // pure-mock mode

    final client = EvcSupabase.client;
    try {
      await client.from('profiles').update({
        'full_name': d.fullName,
        'phone': d.phone,
        if (d.email != null && d.email!.isNotEmpty) 'email': d.email,
      }).eq('id', uid);
    } on PostgrestException catch (e) {
      throw RegistrationException('Could not save your profile: ${e.message}');
    }
  }
}
