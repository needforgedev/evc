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

String docLabel(String type) =>
    kDriverDocTypes.firstWhere((d) => d.$1 == type, orElse: () => (type, type)).$2;

/// Stored state of a single document.
@immutable
class DocInfo {
  const DocInfo({
    required this.reviewStatus,
    required this.storagePath,
    this.expiresAt,
  });
  final String reviewStatus; // pending / approved / rejected
  final String storagePath;
  final DateTime? expiresAt;
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
      .select('type, review_status, storage_path, expires_at')
      .eq('driver_id', uid) as List<dynamic>;

  return {
    for (final r in rows.cast<Map<String, dynamic>>())
      r['type'] as String: DocInfo(
        reviewStatus: (r['review_status'] as String?) ?? 'pending',
        storagePath: (r['storage_path'] as String?) ?? '',
        expiresAt: r['expires_at'] == null
            ? null
            : DateTime.tryParse(r['expires_at'] as String),
      ),
  };
});

/// A live compliance alert for the current driver (most urgent first).
@immutable
class ComplianceAlert {
  const ComplianceAlert({
    required this.docType,
    required this.expiresAt,
    required this.daysBucket,
  });
  final String docType;
  final DateTime expiresAt;
  final int daysBucket; // 60 / 30 / 14 / 7 / 0 (expired)

  bool get isExpired => daysBucket == 0;
  String get label => docLabel(docType);
}

/// Unresolved compliance alerts for the current driver, most urgent first.
final driverComplianceProvider =
    FutureProvider<List<ComplianceAlert>>((ref) async {
  if (!EvcSupabase.isReady) return const [];
  final client = EvcSupabase.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return const [];

  final rows = await client
      .from('compliance_alerts')
      .select('doc_type, expires_at, days_bucket')
      .eq('driver_id', uid)
      .eq('resolved', false)
      .order('days_bucket') as List<dynamic>;

  return rows.cast<Map<String, dynamic>>().map((r) {
    return ComplianceAlert(
      docType: r['doc_type'] as String,
      expiresAt:
          DateTime.tryParse(r['expires_at'] as String? ?? '') ?? DateTime.now(),
      daysBucket: (r['days_bucket'] as int?) ?? 0,
    );
  }).toList();
});

abstract final class DocActions {
  static const String bucket = 'driver-docs';

  /// Uploads [bytes] to Storage and records the document row (pending review).
  /// [expiresAt] is the document's renewal date (drives the compliance engine).
  static Future<void> upload(
    String type,
    Uint8List bytes,
    String ext, {
    DateTime? expiresAt,
  }) async {
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
        if (expiresAt != null)
          'expires_at': expiresAt.toIso8601String().substring(0, 10),
      },
      onConflict: 'driver_id,type',
    );
  }
}
