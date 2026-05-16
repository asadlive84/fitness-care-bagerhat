import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs HTTP requests and responses in debug mode only.
///
/// Logs:
/// - Request method, URL, headers (without auth token)
/// - Response status code and body preview (truncated at 500 chars)
/// - Errors with status code and message
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('──────────────────────────────────────');
      debugPrint('→ ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('→ Body: ${_truncate(options.data.toString())}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('← Data: ${_truncate(response.data.toString())}');
      debugPrint('──────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✖ ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('✖ ${err.message}');
      debugPrint('──────────────────────────────────────');
    }
    handler.next(err);
  }

  String _truncate(String text, [int maxLength = 500]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }
}
