import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fleet_vehicle.dart' show OwnershipType;
import '../supabase/evc_supabase.dart';
import 'dev_auth.dart';

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

/// Registers a driver end-to-end: dev-OTP sign-in, then persist profile +
/// vehicle + (pending) driver record + document metadata. No-op in mock mode.
abstract final class DriverRegistration {
  static Future<void> register(DriverRegistrationData d) async {
    final uid = await EvcDevAuth.signIn(
      role: 'driver',
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
