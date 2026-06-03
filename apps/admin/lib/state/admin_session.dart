import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evc_core/evc_core.dart';

@immutable
class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.scope,
  });

  final String id;
  final String fullName;
  final String email;
  final String scope; // super_admin / ops / finance / support

  String get initials {
    final n = fullName.trim();
    if (n.isEmpty) return 'OP';
    final parts = n.split(RegExp(r'\s+'));
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory AdminProfile.fromRow(Map<String, dynamic> p) => AdminProfile(
        id: p['id'] as String,
        fullName: (p['full_name'] as String?) ?? 'Ops Admin',
        email: (p['email'] as String?) ?? '',
        scope: (p['admin_scope'] as String?) ?? 'ops',
      );
}

class AdminAuthException implements Exception {
  AdminAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The signed-in admin, or null if not signed in / not an admin account.
final currentAdminProvider = FutureProvider<AdminProfile?>((ref) async {
  if (!EvcSupabase.isReady) return null;
  final client = EvcSupabase.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  final p = await client.from('profiles').select().eq('id', uid).single();
  if (p['role'] != 'admin') return null;
  return AdminProfile.fromRow(p);
});

abstract final class AdminAuth {
  /// Email + password login. Admins are provisioned in the Supabase dashboard;
  /// non-admin accounts are rejected.
  static Future<void> signIn(String email, String password) async {
    if (!EvcSupabase.isReady) {
      throw AdminAuthException('Backend not configured (set Supabase creds).');
    }
    final client = EvcSupabase.client;
    final res = await client.auth
        .signInWithPassword(email: email.trim(), password: password);
    final uid = res.user?.id;
    if (uid == null) throw AdminAuthException('Sign-in failed.');

    final p =
        await client.from('profiles').select('role').eq('id', uid).single();
    if (p['role'] != 'admin') {
      await client.auth.signOut();
      throw AdminAuthException('This account is not an admin.');
    }
  }

  static Future<void> signOut() async {
    if (EvcSupabase.isReady) await EvcSupabase.client.auth.signOut();
  }
}
