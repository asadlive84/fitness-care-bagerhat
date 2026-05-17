import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(apiClient: ref.watch(apiClientProvider));
});

class CreateMemberResult {
  final Member member;
  final String tempPassword;

  CreateMemberResult({required this.member, required this.tempPassword});
}

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

  Future<CreateMemberResult> create({
    required String name,
    required String phone,
    required String gender,
    String? goal,
    double? currentWeight,
    double? heightCm,
    DateTime? joinDate,
    DateTime? dateOfBirth,
    String? religion,
    String? bloodGroup,
    List<String>? hobbies,
    String? presentAddress,
    String? permanentAddress,
    String? occupation,
    String? nid,
    String? emergencyPhone,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/admin/members',
      data: {
        'name': name,
        'phone': phone,
        'gender': gender,
        if (goal != null && goal.isNotEmpty) 'goal': goal,
        if (currentWeight != null) 'current_weight': currentWeight,
        if (heightCm != null) 'height_cm': heightCm,
        if (joinDate != null) 'join_date': joinDate.toIso8601String().split('T')[0],
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        if (religion != null && religion.isNotEmpty) 'religion': religion,
        if (bloodGroup != null && bloodGroup.isNotEmpty) 'blood_group': bloodGroup,
        if (hobbies != null && hobbies.isNotEmpty) 'hobbies': hobbies,
        if (presentAddress != null && presentAddress.isNotEmpty) 'present_address': presentAddress,
        if (permanentAddress != null && permanentAddress.isNotEmpty) 'permanent_address': permanentAddress,
        if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
        if (nid != null && nid.isNotEmpty) 'nid': nid,
        if (emergencyPhone != null && emergencyPhone.isNotEmpty) 'emergency_phone': emergencyPhone,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final resultData = data['data'] as Map<String, dynamic>;

    return CreateMemberResult(
      member: Member.fromJson(resultData['member'] as Map<String, dynamic>),
      tempPassword: resultData['temp_password'] as String,
    );
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

  Future<MemberSubscription> assignPlan({
    required String memberId,
    required String planId,
    required double finalPrice,
    DateTime? startDate,
    String? note,
    String billingType = 'prepaid',
    DateTime? prepaidDueDate,
    int? postpaidGraceBefore,
    int? postpaidGraceAfter,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/admin/members/$memberId/subscriptions',
      data: {
        'plan_template_id': planId,
        'final_price': finalPrice,
        'billing_type': billingType,
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
        if (note != null && note.isNotEmpty) 'note': note,
        if (billingType == 'prepaid' && prepaidDueDate != null)
          'prepaid_due_date': prepaidDueDate.toIso8601String().split('T')[0],
        if (billingType == 'postpaid' && postpaidGraceBefore != null)
          'postpaid_grace_before': postpaidGraceBefore,
        if (billingType == 'postpaid' && postpaidGraceAfter != null)
          'postpaid_grace_after': postpaidGraceAfter,
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MemberSubscription.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<ApiResponse<List<MemberSubscription>>> getSubscriptions(String memberId) async {
    final response = await _apiClient.get('/api/v1/admin/members/$memberId/subscriptions');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map((e) => MemberSubscription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<MemberSubscription> updateActiveSubscription({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
    required double finalPrice,
    String? note,
    String billingType = 'prepaid',
    DateTime? prepaidDueDate,
    int? postpaidGraceBefore,
    int? postpaidGraceAfter,
  }) async {
    final response = await _apiClient.patch(
      '/api/v1/admin/members/$memberId/subscriptions/active',
      data: {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'final_price': finalPrice,
        'billing_type': billingType,
        if (note != null && note.isNotEmpty) 'note': note,
        if (billingType == 'prepaid' && prepaidDueDate != null)
          'prepaid_due_date': prepaidDueDate.toIso8601String().split('T')[0],
        if (billingType == 'postpaid' && postpaidGraceBefore != null)
          'postpaid_grace_before': postpaidGraceBefore,
        if (billingType == 'postpaid' && postpaidGraceAfter != null)
          'postpaid_grace_after': postpaidGraceAfter,
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => MemberSubscription.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<String> resetPassword(String memberId) async {
    final response = await _apiClient.post(
      '/api/v1/admin/members/$memberId/password/reset',
    );
    final data = response.data as Map<String, dynamic>;
    final resultData = data['data'] as Map<String, dynamic>;
    return resultData['temp_password'] as String;
  }

  Future<void> deleteMember(String memberId) async {
    await _apiClient.delete('/api/v1/admin/members/$memberId');
  }
}
