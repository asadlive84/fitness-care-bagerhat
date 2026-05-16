/// Sealed hierarchy of API exceptions.
///
/// All network errors thrown by [ApiClient] must be one of these types.
/// Controllers and UI code can switch exhaustively over these.
///
/// ```dart
/// switch (error) {
///   case UnauthorizedException()  => _handleUnauthorized();
///   case ValidationException(:final fields) => _showFieldErrors(fields);
///   case NetworkException()       => _showOffline();
///   // ...
/// }
/// ```
sealed class ApiException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional machine-readable error code from the backend.
  final String? code;

  const ApiException(this.message, {this.code});

  @override
  String toString() => 'ApiException($code): $message';
}

/// 401 — Access token expired or invalid.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Session expired']);
}

/// 403 — Authenticated but lacking permission.
final class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'You do not have permission',
  ]);
}

/// 404 — Resource not found.
final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found']);
}

/// 409 — Duplicate or conflicting resource.
final class ConflictException extends ApiException {
  const ConflictException([super.message = 'Already exists']);
}

/// 422 — Validation failed with per-field error details.
final class ValidationException extends ApiException {
  /// Map of field name → validation message.
  final Map<String, String> fields;

  const ValidationException(
    super.message, {
    required this.fields,
    super.code,
  });
}

/// 429 — Too many requests.
final class RateLimitException extends ApiException {
  const RateLimitException([
    super.message = 'Too many requests. Please wait.',
  ]);
}

/// 5xx — Internal server error.
final class ServerException extends ApiException {
  const ServerException([
    super.message = 'Something went wrong on our end',
  ]);
}

/// No internet or DNS resolution failure.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Server unreachable. Check if backend is running.',
  ]);
}
