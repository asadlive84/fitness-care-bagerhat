import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(apiClient: ref.watch(apiClientProvider));
});

class MemberRepository {
  final ApiClient _apiClient;

  MemberRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ApiResponse<List<Member>>> list({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/admin/members',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status != 'all') 'status': status,
      },
    );

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List).map((e) => Member.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<Member> get(String id) async {
    final response = await _apiClient.get('/api/v1/admin/members/$id');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Member.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<Member> create({
    required String name,
    required String phone,
    String? goal,
    double? currentWeight,
    DateTime? joinDate,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/admin/members',
      data: {
        'name': name,
        'phone': phone,
        if (goal != null) 'goal': goal,
        if (currentWeight != null) 'current_weight': currentWeight,
        if (joinDate != null) 'join_date': joinDate.toIso8601String().split('T')[0],
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) {
        // Backend returns CreateMemberResult: { member: Member, temp_password: string }
        final result = json as Map<String, dynamic>;
        return Member.fromJson(result['member'] as Map<String, dynamic>);
      },
    );
    return apiResponse.data!;
  }

  Future<Member> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/api/v1/admin/members/$id', data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Member.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<void> updateStatus(String id, String status) async {
    await _apiClient.patch(
      '/api/v1/admin/members/$id/status',
      data: {'status': status},
    );
  }

  Future<void> assignPlan({
    required String memberId,
    required String planId,
    required double finalPrice,
    DateTime? startDate,
  }) async {
    await _apiClient.post(
      '/api/v1/admin/members/$memberId/subscriptions',
      data: {
        'plan_template_id': planId,
        'final_price': finalPrice,
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
      },
    );
  }
}
