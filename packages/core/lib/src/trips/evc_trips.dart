import '../models/payment_method.dart';
import '../supabase/evc_supabase.dart';
import 'active_trip.dart';

/// Result of previewing a promo code.
class PromoResult {
  const PromoResult({required this.valid, required this.discount, this.description});
  final bool valid;
  final double discount;
  final String? description;
}

/// A driver's live position (from the `driver_locations` Realtime stream).
class LivePosition {
  const LivePosition({required this.lat, required this.lng, this.heading});
  final double lat;
  final double lng;
  final double? heading;

  factory LivePosition.fromRow(Map<String, dynamic> r) => LivePosition(
        lat: (r['lat'] as num).toDouble(),
        lng: (r['lng'] as num).toDouble(),
        heading: (r['heading'] as num?)?.toDouble(),
      );
}

/// Per-tier driver availability near a pickup (from `nearby_tiers`).
class TierAvailability {
  const TierAvailability({
    required this.tierId,
    required this.drivers,
    required this.etaMin,
  });

  final String tierId;

  /// Eligible drivers of this tier within the service radius.
  final int drivers;

  /// Pickup ETA of the nearest such driver (minutes), or null if none.
  final int? etaMin;

  bool get available => drivers > 0;

  factory TierAvailability.fromRow(Map<String, dynamic> r) => TierAvailability(
        tierId: r['tier_id'] as String,
        drivers: (r['drivers'] as num?)?.toInt() ?? 0,
        etaMin: (r['eta_min'] as num?)?.toInt(),
      );
}

/// Live trip operations against Supabase (request / stream / cancel).
abstract final class EvcTrips {
  /// Rider books a ride: creates the `trips` row, prices it (server-side from
  /// the pricing table), and auto-dispatches the nearest range-capable driver.
  /// Returns the created trip.
  static Future<ActiveTrip> requestRide({
    required String tierId,
    required String pickupName,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destName,
    required String destAddress,
    required double destLat,
    required double destLng,
    required PaymentType paymentType,
    String? promoCode,
  }) async {
    final res = await EvcSupabase.client.rpc('request_ride', params: {
      'p_tier_id': tierId,
      'p_pickup_name': pickupName,
      'p_pickup_address': pickupAddress,
      'p_pickup_lat': pickupLat,
      'p_pickup_lng': pickupLng,
      'p_dest_name': destName,
      'p_dest_address': destAddress,
      'p_dest_lat': destLat,
      'p_dest_lng': destLng,
      'p_payment_type': paymentTypeToDb(paymentType),
      'p_promo_code': promoCode,
    });
    return ActiveTrip.fromRow(_asRow(res));
  }

  /// Per-tier driver availability + pickup ETA near [pickupLat]/[pickupLng] for a
  /// trip of [distanceKm]. Powers the booking screen's "3 min away" / "Unavailable
  /// nearby" hints and the no-driver alternatives.
  static Future<List<TierAvailability>> nearbyTiers({
    required double pickupLat,
    required double pickupLng,
    required double distanceKm,
  }) async {
    final res = await EvcSupabase.client.rpc('nearby_tiers', params: {
      'p_lat': pickupLat,
      'p_lng': pickupLng,
      'p_dist_km': distanceKm,
    });
    return (res as List)
        .map((r) => TierAvailability.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Realtime stream of a single trip row (status updates as it progresses).
  static Stream<ActiveTrip?> tripStream(String id) {
    return EvcSupabase.client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : ActiveTrip.fromRow(rows.first));
  }

  static Future<void> cancel(String id, {String reason = 'Rider canceled'}) =>
      EvcSupabase.client
          .rpc('cancel_trip', params: {'p_trip': id, 'p_reason': reason});

  /// Live position of [driverId] (Realtime). The rider may read their assigned
  /// driver's row while the trip is active (RLS-scoped).
  static Stream<LivePosition?> driverLocationStream(String driverId) {
    return EvcSupabase.client
        .from('driver_locations')
        .stream(primaryKey: ['driver_id'])
        .eq('driver_id', driverId)
        .map((rows) => rows.isEmpty ? null : LivePosition.fromRow(rows.first));
  }

  /// Driver publishes their current position (writes `driver_locations`).
  static Future<void> publishLocation(double lat, double lng,
          {double? heading}) =>
      EvcSupabase.client.rpc('driver_update_location',
          params: {'p_lat': lat, 'p_lng': lng, 'p_heading': heading});

  // ── Driver side ────────────────────────────────────────────
  /// The driver's current active job (matched → ongoing), or null. Realtime.
  static Stream<ActiveTrip?> driverJobStream(String driverId) {
    return EvcSupabase.client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .map((rows) {
      final jobs = rows
          .map(ActiveTrip.fromRow)
          .where((t) => t.status.hasDriver)
          .toList();
      return jobs.isEmpty ? null : jobs.first;
    });
  }

  static Future<ActiveTrip> acceptRide(String id) async {
    final r =
        await EvcSupabase.client.rpc('accept_ride', params: {'p_trip': id});
    return ActiveTrip.fromRow(_asRow(r));
  }

  static Future<void> declineRide(String id) =>
      EvcSupabase.client.rpc('decline_ride', params: {'p_trip': id});

  /// Soft pass (the 30s offer timeout) — re-dispatches but lets this driver be
  /// re-offered the trip on a later round (unlike a hard [declineRide]).
  static Future<void> passRide(String id) =>
      EvcSupabase.client.rpc('pass_ride', params: {'p_trip': id});

  /// Re-attempt matching for waiting (unmatched) trips — called when the driver
  /// pool changes (a driver goes online or finishes a trip) so a queued request
  /// gets picked up as soon as a car becomes available.
  static Future<void> requeueWaiting() async {
    try {
      await EvcSupabase.client.rpc('requeue_waiting_trips');
    } catch (_) {/* best-effort; dispatch also fires on request/decline */}
  }

  /// Advance to `arrived` or `ongoing`.
  static Future<ActiveTrip> advanceTrip(String id, LiveTripStatus to) async {
    final r = await EvcSupabase.client
        .rpc('advance_trip', params: {'p_trip': id, 'p_status': to.name});
    return ActiveTrip.fromRow(_asRow(r));
  }

  static Future<ActiveTrip> completeTrip(String id, {double tip = 0}) async {
    final r = await EvcSupabase.client
        .rpc('complete_trip', params: {'p_trip': id, 'p_tip': tip});
    return ActiveTrip.fromRow(_asRow(r));
  }

  /// Lightweight profile lookup (name / rating / phone) for trip cards.
  static Future<Map<String, dynamic>?> profile(String id) async {
    return await EvcSupabase.client
        .from('profiles')
        .select('full_name, rating, phone')
        .eq('id', id)
        .maybeSingle();
  }

  static Future<void> rate(String tripId, String rateeId, int stars,
          {List<String> tags = const [], String? comment}) =>
      EvcSupabase.client.rpc('rate_trip', params: {
        'p_trip': tripId,
        'p_ratee': rateeId,
        'p_stars': stars,
        'p_tags': tags,
        'p_comment': comment,
      });

  /// Rider-initiated tip on a completed trip (records on trip + payment).
  static Future<void> addTip(String tripId, num amount) =>
      EvcSupabase.client.rpc('add_tip', params: {
        'p_trip': tripId,
        'p_amount': amount,
      });

  /// Previews a promo code against a gross [fare] (no redemption side-effect).
  static Future<PromoResult> validatePromo(String code, num fare) async {
    final res = await EvcSupabase.client
        .rpc('validate_promo', params: {'p_code': code, 'p_fare': fare});
    final m = res as Map?;
    return PromoResult(
      valid: m?['valid'] == true,
      discount: (m?['discount'] as num?)?.toDouble() ?? 0,
      description: m?['description'] as String?,
    );
  }

  // request_ride returns a single `public.trips` row; PostgREST may hand it
  // back as an object or a single-element list depending on version.
  static Map<String, dynamic> _asRow(dynamic res) {
    if (res is Map<String, dynamic>) return res;
    if (res is List && res.isNotEmpty) {
      return (res.first as Map).cast<String, dynamic>();
    }
    throw StateError('Unexpected request_ride response: $res');
  }
}
