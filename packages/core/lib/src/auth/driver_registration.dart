import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/evc_config.dart';
import '../models/fleet_vehicle.dart' show OwnershipType;
import '../supabase/evc_supabase.dart';

/// Everything collected during driver onboarding (phone → details → docs).
class DriverRegistrationData {
  const DriverRegistrationData({
    required this.phone,
    required this.fullName,
    this.email,
    required this.vehicleModel,
    required this.plate,
    required this.ownership,
    required this.batteryPercent,
    required this.rangeKm,
    this.providedDocs = const {},
  });

  final String phone;
  final String fullName;
  final String? email;
  final String vehicleModel;
  final String plate;
  final OwnershipType ownership;
  final int batteryPercent;
  final int rangeKm;

  /// `doc_type` enum values the driver "uploaded" (no bucket yet), e.g.
  /// {'license', 'rta_permit', 'emirates_id', 'vehicle_registration', 'insurance'}.
  final Set<String> providedDocs;
}

class RegistrationException implements Exception {
  RegistrationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Registers a driver end-to-end against Supabase using the dev OTP scheme:
/// any phone + fixed code, backed by a deterministic email/password so we still
/// get a real session (JWT + RLS). No-op (mock success) when creds aren't set.
abstract final class DriverRegistration {
  /// Deterministic synthetic email so the same phone always maps to the same
  /// account (phone stays the real identity, stored on the profile).
  static String emailForPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@evc-driver.test';
  }

  static const String _devPassword = 'evc-dev-7464';

  static Future<void> register(DriverRegistrationData d) async {
    // Pure-mock mode until creds are added — flow still works, nothing persisted.
    if (!EvcSupabase.isReady) return;

    final client = EvcSupabase.client;
    final email = emailForPhone(d.phone);

    // Create the account (first time) or sign in (returning driver). The
    // handle_new_user trigger makes profiles + driver_details(pending).
    try {
      await client.auth.signUp(
        email: email,
        password: _devPassword,
        data: {'role': 'driver', 'full_name': d.fullName, 'phone': d.phone},
      );
    } on AuthException {
      await client.auth.signInWithPassword(email: email, password: _devPassword);
    }

    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw RegistrationException('Could not establish a session.');
    }

    try {
      // Profile (phone/email aren't on the auth row for email signups).
      await client.from('profiles').update({
        'full_name': d.fullName,
        'phone': d.phone,
        if (d.email != null && d.email!.isNotEmpty) 'email': d.email,
      }).eq('id', uid);

      // Vehicle (RLS: owner_driver_id must equal auth.uid()).
      final vehicle = await client
          .from('vehicles')
          .insert({
            'plate': d.plate,
            'model': d.vehicleModel,
            'ownership': d.ownership.name,
            'owner_driver_id': uid,
            'battery_percent': d.batteryPercent,
            'range_km': d.rangeKm,
            'status': 'active',
          })
          .select('id')
          .single();

      // Link the vehicle + owner label onto the (pending) driver record.
      await client.from('driver_details').update({
        'current_vehicle_id': vehicle['id'],
        'owner_label': d.ownership == OwnershipType.company
            ? 'Company-owned'
            : 'Driver-owned',
      }).eq('driver_id', uid);

      // Document metadata only — no storage bucket yet.
      if (d.providedDocs.isNotEmpty) {
        await client.from('driver_documents').upsert(
          [
            for (final type in d.providedDocs)
              {
                'driver_id': uid,
                'type': type,
                'storage_path': 'mock://no-bucket',
                'review_status': 'pending',
              },
          ],
          onConflict: 'driver_id,type',
        );
      }
    } on PostgrestException catch (e) {
      throw RegistrationException('Could not save driver details: ${e.message}');
    }
  }
}

/// Convenience: matches the entered code against the dev OTP.
bool verifyDevOtp(String code) =>
    EvcConfig.devMockOtp && code == EvcConfig.devOtpCode;
