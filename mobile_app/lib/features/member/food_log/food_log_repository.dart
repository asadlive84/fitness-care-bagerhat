import 'package:dio/dio.dart';
import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/member/food_log/food_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final foodLogRepositoryProvider = Provider<FoodLogRepository>((ref) {
  return FoodLogRepository(apiClient: ref.watch(apiClientProvider));
});

class FoodLogRepository {
  final ApiClient _apiClient;

  FoodLogRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<FoodLog>> list({int limit = 100, int offset = 0}) async {
    final response = await _apiClient.get(
      '/api/v1/ai/food-logs',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map((e) => FoodLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiResponse.data ?? [];
  }

  Future<String> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.post(
      '/api/v1/upload',
      data: formData,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) {
        if (json is Map<String, dynamic>) {
          return json['url'] as String? ?? json['data'] as String? ?? '';
        }
        return json as String;
      },
    );
    
    return apiResponse.data!;
  }

  Future<NutritionData> analyzeImage(String imageUrl) async {
    final response = await _apiClient.post(
      '/api/v1/ai/food-log',
      data: {
        'image_url': imageUrl,
      },
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) {
        if (json is Map<String, dynamic>) {
          return NutritionData.fromJson(json);
        }
        return const NutritionData();
      },
    );

    return apiResponse.data ?? const NutritionData();
  }
}
