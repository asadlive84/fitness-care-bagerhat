import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(apiClient: ref.watch(apiClientProvider));
});

class PlanRepository {
  final ApiClient _apiClient;

  PlanRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ApiResponse<List<Plan>>> list({bool? activeOnly}) async {
    final response = await _apiClient.get(
      '/api/v1/admin/plans',
      queryParameters: {
        if (activeOnly != null) 'active_only': activeOnly,
      },
    );

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List).map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<Plan> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/api/v1/admin/plans', data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Plan.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<Plan> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/api/v1/admin/plans/$id', data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Plan.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/api/v1/admin/plans/$id');
  }
}
