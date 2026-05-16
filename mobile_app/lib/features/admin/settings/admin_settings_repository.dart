import 'dart:convert';

import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminSettingsRepositoryProvider = Provider<AdminSettingsRepository>((ref) {
  return AdminSettingsRepository(apiClient: ref.watch(apiClientProvider));
});

/// A single settings key-value entry.
class AppSetting {
  const AppSetting({required this.key, required this.value});

  final String key;

  /// Raw JSON value — could be a number, string, or object.
  final dynamic value;

  factory AppSetting.fromJson(Map<String, dynamic> json) => AppSetting(
        key: json['key'] as String,
        value: json['value'],
      );

  /// Returns [value] as an int, or [fallback] if it cannot be parsed.
  int asInt([int fallback = 0]) {
    if (value is int) return value as int;
    if (value is double) return (value as double).toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  /// Returns [value] as a String, or empty string.
  String asString() => value?.toString() ?? '';
}

class AdminSettingsRepository {
  final ApiClient _apiClient;

  AdminSettingsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<AppSetting>> getAll() async {
    final response = await _apiClient.get('/api/v1/admin/settings');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map((e) => AppSetting.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<AppSetting> upsert({
    required String key,
    required dynamic value,
  }) async {
    final response = await _apiClient.patch(
      '/api/v1/admin/settings',
      data: {
        'key': key,
        'value': value,
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => AppSetting.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
