import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides the singleton [TokenStorage] instance.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// Secure storage wrapper for authentication tokens.
///
/// Stores access and refresh JWT tokens in platform-secure storage
/// (Keychain on iOS, EncryptedSharedPreferences on Android).
///
/// See also:
/// - [TokenInterceptor] which reads tokens for request injection
/// - [AuthRepository] which writes tokens after login/refresh
class TokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ─── Tokens ────────────────────────────────────────────

  /// Saves both access and refresh tokens atomically.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Retrieves the current access token, or null if not logged in.
  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);

  /// Retrieves the current refresh token, or null if not logged in.
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  /// Returns true if tokens exist (does not validate expiry).
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ─── User Info ─────────────────────────────────────────

  /// Saves basic user info alongside tokens.
  Future<void> saveUserInfo({
    required String userId,
    required String role,
    required String name,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserRole, value: role),
      _storage.write(key: _keyUserName, value: name),
    ]);
  }

  /// Gets the stored user ID.
  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  /// Gets the stored user role ('admin' or 'member').
  Future<String?> getUserRole() => _storage.read(key: _keyUserRole);

  /// Gets the stored user display name.
  Future<String?> getUserName() => _storage.read(key: _keyUserName);

  // ─── Clear ─────────────────────────────────────────────

  /// Clears all stored tokens and user info (logout).
  Future<void> clearAll() => _storage.deleteAll();
}
