import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberHomeRepositoryProvider = Provider<MemberHomeRepository>((ref) {
  return MemberHomeRepository(apiClient: ref.watch(apiClientProvider));
});

class MemberHomeRepository {
  final ApiClient _apiClient;

  MemberHomeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Member> getProfile() async {
    final response = await _apiClient.get('/api/v1/member/profile');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Member.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<MemberSubscription?> getActiveSubscription() async {
    final response = await _apiClient.get('/api/v1/member/subscription');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json != null ? MemberSubscription.fromJson(json as Map<String, dynamic>) : null,
    );
    return apiResponse.data;
  }

  Future<List<ChartPoint>> getWeightTrend() async {
    final response = await _apiClient.get('/api/v1/member/weight-logs');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List<dynamic>).map((e) {
        final date = DateTime.parse(e['logged_at'] as String);
        return ChartPoint(
          label: '${date.day}/${date.month}',
          value: (e['weight_kg'] as num).toDouble(),
        );
      }).toList(),
    );
    // Backend returns DESC (newest first). Chart needs ASC (oldest first).
    return apiResponse.data?.reversed.toList() ?? [];
  }
}
