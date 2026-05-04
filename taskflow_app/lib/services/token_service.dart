import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages reading, writing, and clearing the Firebase ID token
/// from the device's secure storage.
///
/// Usage:
///   final token = await TokenService.instance.getToken();
class TokenService {
  TokenService._();
  static final TokenService instance = TokenService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'firebase_id_token';

  /// Saves [token] to secure storage.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieves the stored token, or null if none exists.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Deletes the stored token (call this on logout).
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
