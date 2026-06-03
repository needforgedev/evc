import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

const _tierNames = {
  'go': 'EVC Go',
  'comfort': 'EVC Comfort',
  'xl': 'EVC XL',
  'premium': 'EVC Green Premium',
};

String _dateLabel(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)} · ${two(d.hour)}:${two(d.minute)}';
}

/// The rider's completed trips, newest first (real; empty for a new rider).
final rideHistoryProvider = FutureProvider<List<TripHistoryEntry>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return const [];

  final rows = await client
      .from('trips')
      .select()
      .eq('rider_id', uid)
      .eq('status', 'completed')
      .order('completed_at', ascending: false) as List<dynamic>;

  return [
    for (final r in rows.cast<Map<String, dynamic>>())
      TripHistoryEntry(
        dateLabel: _dateLabel(r['completed_at'] as String?),
        fromName: (r['pickup_name'] ?? r['pickup_address'] ?? 'Pickup') as String,
        toName: (r['dest_name'] ?? r['dest_address'] ?? 'Destination') as String,
        tierName: _tierNames[r['tier_id']] ?? (r['tier_id'] as String? ?? ''),
        fareAed: (r['final_fare'] as num?)?.toDouble() ?? 0,
        co2SavedKg: (r['co2_saved_kg'] as num?)?.toDouble() ?? 0,
      ),
  ];
});
