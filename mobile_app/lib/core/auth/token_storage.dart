import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

// Uses SharedPreferences instead of FlutterSecureStorage to avoid
// Android Keystore silent hang on Samsung/MIUI devices.
class TokenStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ─── Tokens ────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(_keyAccessToken, accessToken),
      prefs.setString(_keyRefreshToken, refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyRefreshToken);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ─── User Info ─────────────────────────────────────────

  Future<void> saveUserInfo({
    required String userId,
    required String role,
    required String name,
  }) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(_keyUserId, userId),
      prefs.setString(_keyUserRole, role),
      prefs.setString(_keyUserName, name),
    ]);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserId);
  }

  Future<String?> getUserRole() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserRole);
  }

  Future<String?> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserName);
  }

  // ─── Clear ─────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_keyAccessToken),
      prefs.remove(_keyRefreshToken),
      prefs.remove(_keyUserId),
      prefs.remove(_keyUserRole),
      prefs.remove(_keyUserName),
    ]);
  }
}
