import 'dart:convert';
import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/core/auth/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [AuthRepository] singleton.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// Handles authentication API calls and credential management.
///
/// Communicates with the backend auth endpoints and stores
/// tokens via [TokenStorage].
///
/// Throws [ApiException] subclasses on error — never raw [DioException].
///
/// See also:
/// - [AuthProvider] which manages the [AuthState]
/// - [TokenInterceptor] which uses stored tokens for request injection
class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  /// Attempts login with email/phone and password.
  ///
  /// Returns a map with user info on success. Stores tokens automatically.
  ///
  /// Throws:
  /// - [UnauthorizedException] if credentials are invalid
  /// - [ValidationException] if fields fail server validation
  /// - [ServerException] on unexpected server error
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/auth/$role/login',
      data: {
        if (role == 'admin') 'email': identifier else 'phone': identifier,
        'password': password,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Invalid server response format');
    }

    if (data['success'] != true) {
      throw const UnauthorizedException('Invalid credentials');
    }

    final authData = data['data'] as Map<String, dynamic>;

    final accessToken = authData['access_token'] as String;
    final refreshToken = authData['refresh_token'] as String;

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Decode JWT to get user info (role and userId)
    final claims = _decodeJwt(accessToken);
    final userId = claims['sub']?.toString() ?? '';
    final jwtRole = claims['role']?.toString() ?? role;

    await _tokenStorage.saveUserInfo(
      userId: userId,
      role: jwtRole,
      name: '', // We'll fetch the profile later or use email as name
    );

    return authData;
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64.normalize(payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      ));
      return json.decode(utf8.decode(base64.decode(normalized))) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Changes the user's password.
  ///
  /// Throws:
  /// - [ValidationException] if current password is wrong or new password is weak
  /// - [UnauthorizedException] if session is expired
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/api/v1/auth/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Logs out the user by clearing stored tokens.
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  /// Checks whether the user is currently authenticated.
  Future<bool> isAuthenticated() => _tokenStorage.hasTokens();

  /// Returns the stored user role, or null if not logged in.
  Future<String?> getUserRole() => _tokenStorage.getUserRole();

  /// Returns the stored user name, or null if not logged in.
  Future<String?> getUserName() => _tokenStorage.getUserName();
}
