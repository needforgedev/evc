/// Runtime configuration for the EVC apps.
///
/// Supabase credentials are injected at build/run time via `--dart-define`
/// (never hardcoded / committed). See supabase/README.md.
abstract final class EvcConfig {
  /// Supabase project URL, e.g. https://xyzcompany.supabase.co (or the local
  /// `supabase start` URL http://127.0.0.1:54321).
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Supabase anon (public) key.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True once both creds are supplied — gates whether we talk to the backend
  /// or fall back to a pure-mock flow.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── Dev OTP (no SMS provider yet) ─────────────────────────────
  /// Any phone number can sign in with this fixed code during development.
  /// REMOVE / replace with real OTP before launch.
  static const String devOtpCode =
      String.fromEnvironment('DEV_OTP_CODE', defaultValue: '7464');

  /// Whether the fixed-code dev OTP gate is active.
  static const bool devMockOtp =
      bool.fromEnvironment('DEV_MOCK_OTP', defaultValue: true);

  // ── Google Maps ───────────────────────────────────────────────
  /// Google Maps API key. The *native SDK* key is injected separately (Android
  /// via Gradle manifest placeholder from `.env`; iOS via Info.plist). This
  /// Dart-side copy is used for the HTTP Places/Directions calls (later slices).
  static const String gmapsApiKey =
      String.fromEnvironment('GMAPS_API_KEY', defaultValue: '');

  /// Dev: stream a *simulated* driver path along the active trip instead of real
  /// device GPS, so the live driver dot can be demoed from a simulator outside
  /// the UAE. Set `--dart-define=SIMULATE_DRIVER_GPS=false` on a real UAE device.
  static const bool simulateDriverGps =
      bool.fromEnvironment('SIMULATE_DRIVER_GPS', defaultValue: true);
}
