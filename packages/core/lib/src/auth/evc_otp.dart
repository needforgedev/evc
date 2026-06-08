import '../supabase/evc_supabase.dart';

class OtpException implements Exception {
  OtpException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Real OTP verification via the `request-otp` / `verify-otp` Edge Functions.
/// (Delivery in dev is the Vonage WhatsApp sandbox.)
abstract final class EvcOtp {
  /// Sends a fresh code to [phone] (dev: delivered to the sandbox number).
  static Future<void> requestOtp(String phone) async {
    if (!EvcSupabase.isReady) throw OtpException('Backend not configured.');
    final res = await EvcSupabase.client.functions
        .invoke('request-otp', body: {'phone': phone});
    if (res.status != 200) {
      final data = res.data;
      final detail = data is Map ? (data['error'] ?? data['detail']) : null;
      throw OtpException('Could not send code${detail != null ? ': $detail' : ''}');
    }
  }

  /// Returns true if [code] is valid for [phone].
  static Future<bool> verifyOtp(String phone, String code) async {
    if (!EvcSupabase.isReady) return false;
    final res = await EvcSupabase.client.functions
        .invoke('verify-otp', body: {'phone': phone, 'code': code});
    final data = res.data;
    return data is Map && data['verified'] == true;
  }
}
