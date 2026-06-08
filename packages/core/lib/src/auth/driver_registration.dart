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
  });

  final String phone;
  final String fullName;
  final String? email;
  final String vehicleModel;
  final String plate;
  final OwnershipType ownership;
  final int batteryPercent;
  final int rangeKm;
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

      final ownerLabel =
          d.ownership == OwnershipType.company ? 'Company-owned' : 'Driver-owned';

      // Idempotent: only create a vehicle if the driver doesn't already have one
      // (prevents duplicate vehicle rows on re-registration / re-login).
      final details = await client
          .from('driver_details')
          .select('current_vehicle_id')
          .eq('driver_id', uid)
          .maybeSingle();

      if (details?['current_vehicle_id'] == null) {
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
          'owner_label': ownerLabel,
        }).eq('driver_id', uid);
      } else {
        await client
            .from('driver_details')
            .update({'owner_label': ownerLabel}).eq('driver_id', uid);
      }
      // Documents are uploaded separately, after sign-up (Documents screen).
    } on PostgrestException catch (e) {
      throw RegistrationException('Could not save driver details: ${e.message}');
    }
  }
}
