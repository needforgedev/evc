import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:evc_core/evc_core.dart';

/// All requestable driver documents (`doc_type` enum value → label).
const List<(String, String)> kDriverDocTypes = [
  ('license', 'Driving license'),
  ('rta_permit', 'RTA driver permit'),
  ('emirates_id', 'Emirates ID'),
  ('vehicle_registration', 'Vehicle registration'),
  ('insurance', 'Insurance'),
];

/// Stored state of a single document.
@immutable
class DocInfo {
  const DocInfo({required this.reviewStatus, required this.storagePath});
  final String reviewStatus; // pending / approved / rejected
  final String storagePath;
}

/// The current driver's uploaded documents, keyed by `doc_type`.
final driverDocumentsProvider =
    FutureProvider<Map<String, DocInfo>>((ref) async {
  if (!EvcSupabase.isReady) return const {};
  final client = EvcSupabase.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return const {};

  final rows = await client
      .from('driver_documents')
      .select('type, review_status, storage_path')
      .eq('driver_id', uid) as List<dynamic>;

  return {
    for (final r in rows.cast<Map<String, dynamic>>())
      r['type'] as String: DocInfo(
        reviewStatus: (r['review_status'] as String?) ?? 'pending',
        storagePath: (r['storage_path'] as String?) ?? '',
      ),
  };
});

abstract final class DocActions {
  static const String bucket = 'driver-docs';

  /// Uploads [bytes] to Storage and records the document row (pending review).
  static Future<void> upload(String type, Uint8List bytes, String ext) async {
    if (!EvcSupabase.isReady) return;
    final client = EvcSupabase.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    final path = '$uid/$type.$ext';
    await client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await client.from('driver_documents').upsert(
      {
        'driver_id': uid,
        'type': type,
        'storage_path': path,
        'review_status': 'pending',
      },
      onConflict: 'driver_id,type',
    );
  }
}
