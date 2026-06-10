import '../models/payment_method.dart';
import '../supabase/evc_supabase.dart';
import 'active_trip.dart';

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
