import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(apiClient: ref.watch(apiClientProvider));
});

class PlanRepository {
  final ApiClient _apiClient;

  PlanRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch plans with optional period filter.
  ///
  /// Pass [month] as 'YYYY-MM' for monthly view,
  /// or [from]/[to] as 'YYYY-MM-DD' for a custom range.
  /// Omit all for lifetime mode.
  Future<PlansApiResponse> list({
    String? month,
    String? from,
    String? to,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/admin/plans',
      queryParameters: {
        if (month != null) 'month': month,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];

    // The backend returns either:
    //   NEW format → data is an object {filter, summary, plans: [...]}
    //   OLD format → data is a list  [{plan+subscribers}, ...]
    if (raw is List) {
      return PlansApiResponse.fromList(raw, period: month != null ? 'monthly' : (from != null ? 'custom' : 'lifetime'));
    }
    return PlansApiResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<Plan> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/api/v1/admin/plans', data: data);
    final body = response.data as Map<String, dynamic>;
    return Plan.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Plan> update(String id, Map<String, dynamic> data) async {
    final response =
        await _apiClient.patch('/api/v1/admin/plans/$id', data: data);
    final body = response.data as Map<String, dynamic>;
    return Plan.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/api/v1/admin/plans/$id');
  }
}
