import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

const Map<String, String> kDocLabels = {
  'license': 'Driving license',
  'rta_permit': 'RTA driver permit',
  'emirates_id': 'Emirates ID',
  'vehicle_registration': 'Vehicle registration',
  'insurance': 'Insurance',
};

class DriverDoc {
  const DriverDoc({
    required this.id,
    required this.type,
    required this.reviewStatus,
    required this.storagePath,
  });

  final String id;
  final String type;
  final String reviewStatus; // pending / approved / rejected
  final String storagePath;
}

/// A driver's uploaded documents (admin view).
final driverDocsProvider =
    FutureProvider.family<List<DriverDoc>, String>((ref, driverId) async {
  if (!EvcSupabase.isReady) return const [];
  final rows = await EvcSupabase.client
      .from('driver_documents')
      .select('id, type, review_status, storage_path')
      .eq('driver_id', driverId) as List<dynamic>;
  return [
    for (final r in rows.cast<Map<String, dynamic>>())
      DriverDoc(
        id: r['id'] as String,
        type: r['type'] as String,
        reviewStatus: (r['review_status'] as String?) ?? 'pending',
        storagePath: (r['storage_path'] as String?) ?? '',
      ),
  ];
});

abstract final class AdminDocActions {
  /// Short-lived signed URL to view a private document.
  static Future<String> signedUrl(String path) => EvcSupabase.client.storage
      .from('driver-docs')
      .createSignedUrl(path, 120);

  /// Approve / reject a single document (RLS allows admin updates).
  static Future<void> review(String docId, String status) async {
    if (!EvcSupabase.isReady) return;
    final uid = EvcSupabase.client.auth.currentUser?.id;
    await EvcSupabase.client
        .from('driver_documents')
        .update({'review_status': status, 'reviewed_by': uid}).eq('id', docId);
  }
}
