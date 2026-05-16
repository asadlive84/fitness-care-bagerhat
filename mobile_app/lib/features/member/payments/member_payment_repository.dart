import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberPaymentRepositoryProvider = Provider<MemberPaymentRepository>((ref) {
  return MemberPaymentRepository(apiClient: ref.watch(apiClientProvider));
});

class MemberPaymentRepository {
  final ApiClient _apiClient;

  MemberPaymentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ApiResponse<List<Payment>>> list({DateTime? from, DateTime? to}) async {
    final response = await _apiClient.get(
      '/api/v1/member/payments',
      queryParameters: {
        if (from != null) 'from': from.toIso8601String().split('T')[0],
        if (to != null) 'to': to.toIso8601String().split('T')[0],
      },
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          (json as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Calculates total paid for the member's current active subscription.
final memberActiveSubPaidProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final repo = ref.watch(memberPaymentRepositoryProvider);
  final response = await repo.list();
  final payments = response.data ?? [];

  // Get active subscription ID from home state
  final homeState = ref.watch(memberHomeControllerProvider);
  final subId = homeState.valueOrNull?.activeSubscription?.id;

  if (subId == null) return 0.0;

  return payments
      .where((p) => p.subscriptionId == subId)
      .fold<double>(0.0, (sum, p) => sum + p.amount);
});
