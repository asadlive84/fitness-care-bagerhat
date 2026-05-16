import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/core/api/interceptors/logging_interceptor.dart';
import 'package:fitness_care_bagerhat/core/api/interceptors/token_interceptor.dart';
import 'package:fitness_care_bagerhat/core/auth/token_storage.dart';
import 'package:fitness_care_bagerhat/core/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton [Dio] HTTP client.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  return ApiClient(
    tokenStorage: tokenStorage,
    baseUrl: settings.baseUrl,
  );
});

/// Centralized HTTP client wrapping [Dio].
///
/// Automatically injects Bearer tokens via [TokenInterceptor],
/// logs requests in debug mode via [LoggingInterceptor], and
/// converts all [DioException]s into typed [ApiException]s.
///
/// Usage:
/// ```dart
/// final client = ref.read(apiClientProvider);
/// final response = await client.get('/api/v1/members');
/// ```
class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({
    required TokenStorage tokenStorage,
    required String baseUrl,
  }) : _tokenStorage = tokenStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      TokenInterceptor(dio: _dio, tokenStorage: _tokenStorage),
      LoggingInterceptor(),
    ]);
  }

  /// The raw [Dio] instance — prefer using typed methods below.
  Dio get dio => _dio;

  /// Performs a GET request and returns the response data.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Performs a POST request.
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Performs a PUT request.
  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Performs a PATCH request.
  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Performs a DELETE request.
  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// Maps Dio errors to our sealed [ApiException] hierarchy.
  ApiException _mapException(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    // Extract error message from backend envelope
    String message;
    String? code;
    Map<String, String>? fieldErrors;

    if (responseData is Map<String, dynamic>) {
      final errorObj = responseData['error'];
      if (errorObj is Map<String, dynamic>) {
        message = errorObj['message'] as String? ?? e.message ?? 'Unknown error';
        code = errorObj['code'] as String?;
        final details = errorObj['details'];
        if (details is Map<String, dynamic>) {
          fieldErrors = details.map(
            (key, value) => MapEntry(key, value.toString()),
          );
        }
      } else {
        message = e.message ?? 'Unknown error';
      }
    } else {
      message = e.message ?? 'Unknown error';
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled');
      case _:
        break;
    }

    if (statusCode == null) {
      return ServerException(message);
    }

    return switch (statusCode) {
      401 => UnauthorizedException(message),
      403 => ForbiddenException(message),
      404 => NotFoundException(message),
      409 => ConflictException(message),
      422 => ValidationException(
          message,
          fields: fieldErrors ?? {},
          code: code,
        ),
      429 => const RateLimitException(),
      >= 500 => ServerException(message),
      _ => ServerException(message),
    };
  }
}
