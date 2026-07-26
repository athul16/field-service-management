import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

/// Handles worker registration and login using phone-based OTP.
///
/// Flow:
/// 1. Worker enters name, phone (required), email (optional) -> [sendOtp]
/// 2. Worker enters the code they received by SMS -> [verifyOtpAndCreateProfile]
///    or [verifyOtpForLogin] for returning workers.
///
/// NOTE: Phone OTP delivery requires an SMS provider (e.g. Twilio) to be
/// configured in the Supabase dashboard under Authentication > Providers > Phone.
class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> sendOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  /// Verifies the OTP for a brand-new worker and creates their profile row.
  Future<void> verifyOtpAndCreateProfile({
    required String phone,
    required String otpCode,
    required String fullName,
    String? email,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: otpCode,
    );

    final user = response.user;
    if (user == null) {
      throw StateError('OTP verification did not return a user.');
    }

    await _client.from('profiles').upsert({
      'id': user.id,
      'role': 'worker',
      'full_name': fullName,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    });
  }

  /// Verifies the OTP for a returning worker (profile already exists).
  Future<void> verifyOtpForLogin({
    required String phone,
    required String otpCode,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: otpCode,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
