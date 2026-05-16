import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberProfileRepositoryProvider = Provider<MemberProfileRepository>((ref) {
  return MemberProfileRepository(apiClient: ref.watch(apiClientProvider));
});

class MemberProfileRepository {
  final ApiClient _apiClient;

  MemberProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Member> getProfile() async {
    final response = await _apiClient.get('/api/v1/member/profile');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Member.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<Member> updateProfile({
    required String name,
    String? goal,
    double? currentWeight,
  }) async {
    final response = await _apiClient.patch(
      '/api/v1/member/profile',
      data: {
        'name': name,
        if (goal != null) 'goal': goal,
        if (currentWeight != null) 'current_weight': currentWeight,
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Member.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
