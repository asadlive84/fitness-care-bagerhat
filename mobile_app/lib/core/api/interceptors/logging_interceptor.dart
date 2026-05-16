import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs HTTP requests and responses for debugging.
///
/// Logs:
/// - Request method, URL, headers
/// - Full response body
/// - Errors with status code and message
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('🚀 [API REQUEST] ${options.method} ${options.uri}');
      print('🚀 [HEADERS] ${options.headers}');
      if (options.data != null) {
        print('🚀 [BODY] ${options.data}');
      }
      print('──────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      print('✅ [API RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
      print('✅ [DATA] ${response.data}');
      print('──────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('❌ [API ERROR] ${err.response?.statusCode} ${err.requestOptions.uri}');
      print('❌ [MESSAGE] ${err.message}');
      if (err.response?.data != null) {
        print('❌ [ERROR DATA] ${err.response?.data}');
      }
      print('──────────────────────────────────────');
    }
    handler.next(err);
  }
}
