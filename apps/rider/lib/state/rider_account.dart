import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

/// The signed-in rider's profile.
@immutable
class RiderProfile {
  const RiderProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.rating,
    required this.totalTrips,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final double rating;
  final int totalTrips;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'EV';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory RiderProfile.fromRow(Map<String, dynamic> p) => RiderProfile(
        id: p['id'] as String,
        fullName: (p['full_name'] as String?) ?? 'Rider',
        phone: (p['phone'] as String?) ?? '',
        email: (p['email'] as String?) ?? '',
        rating: (p['rating'] as num?)?.toDouble() ?? 5.0,
        totalTrips: (p['total_trips'] as num?)?.toInt() ?? 0,
      );
}

/// Loads the current rider from Supabase. Null when not signed in / not
/// configured (the app then stays in pure-mock mode).
final currentRiderProvider = FutureProvider<RiderProfile?>((ref) async {
  if (!EvcSupabase.isReady) return null;
  final client = EvcSupabase.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  final p = await client.from('profiles').select().eq('id', uid).single();
  return RiderProfile.fromRow(p);
});

abstract final class RiderActions {
  static Future<void> signOut() async {
    if (EvcSupabase.isReady) await EvcSupabase.client.auth.signOut();
  }
}
