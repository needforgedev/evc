import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/evc_config.dart';

/// Thin wrapper around Supabase initialisation so apps just call
/// `await EvcSupabase.init()` in `main()`.
abstract final class EvcSupabase {
  /// Initialises Supabase if creds are configured; otherwise a no-op so the
  /// apps still run in pure-mock mode.
  static Future<void> init() async {
    if (!EvcConfig.isSupabaseConfigured) return;
    await Supabase.initialize(
      url: EvcConfig.supabaseUrl,
      anonKey: EvcConfig.supabaseAnonKey,
    );
  }

  /// The active client. Only valid when [EvcConfig.isSupabaseConfigured].
  static SupabaseClient get client => Supabase.instance.client;

  static bool get isReady => EvcConfig.isSupabaseConfigured;

  /// True when a session was restored from storage — used to skip onboarding /
  /// login on subsequent launches.
  static bool get hasSession =>
      isReady && Supabase.instance.client.auth.currentSession != null;

  static String? get currentUserId =>
      isReady ? Supabase.instance.client.auth.currentUser?.id : null;
}
