/// EVC shared core.
///
/// Domain models, app identity, and (soon) the Supabase client, auth and
/// Riverpod DI — compiled into all three apps as the single source of truth.
library;

export 'src/app_identity.dart';
export 'src/models/place.dart';
export 'src/models/ride_tier.dart';
export 'src/models/driver_profile.dart';
export 'src/models/trip.dart';
export 'src/models/payment_method.dart';
export 'src/models/rider_info.dart';
export 'src/models/ride_request.dart';
export 'src/models/charging_station.dart';
export 'src/models/earnings.dart';
export 'src/models/fleet_vehicle.dart';
export 'src/models/driver_record.dart';
export 'src/models/admin_trip.dart';
export 'src/models/support_ticket.dart';

export 'src/config/evc_config.dart';
export 'src/supabase/evc_supabase.dart';
export 'src/auth/dev_auth.dart';
export 'src/auth/evc_otp.dart';
export 'src/auth/driver_registration.dart';
export 'src/auth/rider_registration.dart';
export 'src/trips/active_trip.dart';
export 'src/trips/evc_trips.dart';
export 'src/pricing/evc_pricing.dart';
export 'src/places/evc_saved_places.dart';
