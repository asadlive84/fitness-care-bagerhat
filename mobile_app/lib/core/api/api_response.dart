/// Generic API response envelope parser.
///
/// The backend wraps all responses in:
/// ```json
/// { "success": true, "data": {...}, "meta": {...} }
/// ```
///
/// This class provides type-safe parsing of that envelope.
class ApiResponse<T> {
  /// Whether the request succeeded.
  final bool success;

  /// Parsed response data.
  final T? data;

  /// Optional error information.
  final ApiError? error;

  /// Optional pagination metadata.
  final PaginationMeta? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.meta,
  });

  /// Parses a JSON map into an [ApiResponse].
  ///
  /// [fromJson] converts the `data` field into type [T].
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'])
          : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Error object returned by the backend.
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'An error occurred',
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}

/// Pagination metadata from paginated list responses.
class PaginationMeta {
  final int page;
  final int limit;
  final int total;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
  });

  /// Total number of pages.
  int get totalPages => (total / limit).ceil();

  /// Whether there are more pages after the current one.
  bool get hasMore => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
    );
  }
}
