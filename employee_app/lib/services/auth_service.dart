import '../core/api_client.dart';

/// Worker login: phone + PIN against the backend's own credential store
/// (see backend's AuthService/JwtService) — no Supabase involved at all.
/// The backend infers "who is making this request" from the JWT on every
/// other call, so nothing here needs to track or pass a worker id around.
class AuthService {
  final _client = ApiClient.instance;

  Future<void> signInWithPin({required String phone, required String pin}) async {
    final response = await _client.post('/api/auth/login', body: {'phone': phone, 'pin': pin});
    await _client.setToken(response['token'] as String);
  }

  Future<void> signOut() => _client.clearToken();
}
