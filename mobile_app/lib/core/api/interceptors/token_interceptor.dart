import 'package:dio/dio.dart';
import 'package:fitness_care_bagerhat/core/auth/token_storage.dart';
import 'package:flutter/foundation.dart';

/// Injects Bearer token and handles silent refresh on 401.
///
/// Flow:
/// 1. Before each request → inject `Authorization: Bearer <access_token>`
/// 2. On 401 response → attempt token refresh via POST /api/v1/auth/refresh
/// 3. On successful refresh → store new tokens and retry original request
/// 4. On failed refresh → clear storage (forces re-login)
class TokenInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Separate Dio instance for refresh to avoid interceptor loops.
  late final Dio _refreshDio;

  TokenInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage {
    _refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't try to refresh if this IS the refresh request
    if (err.requestOptions.path.contains('/auth/refresh')) {
      await _tokenStorage.clearAll();
      return handler.next(err);
    }

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await _tokenStorage.clearAll();
        return handler.next(err);
      }

      // Attempt silent refresh
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final tokenData = data['data'] as Map<String, dynamic>;
        final newAccessToken = tokenData['access_token'] as String;
        final newRefreshToken = tokenData['refresh_token'] as String;

        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry original request with new token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await _dio.fetch<dynamic>(retryOptions);
        return handler.resolve(retryResponse);
      }

      await _tokenStorage.clearAll();
      return handler.next(err);
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _tokenStorage.clearAll();
      return handler.next(err);
    }
  }
}
