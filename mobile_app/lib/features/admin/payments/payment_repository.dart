import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(apiClient: ref.watch(apiClientProvider));
});

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ApiResponse<List<Payment>>> list({
    String? memberId,
    int page = 1,
    DateTime? from,
    DateTime? to,
  }) async {
    final path = memberId != null 
      ? '/api/v1/admin/members/$memberId/payments'
      : '/api/v1/admin/payments';
    final response = await _apiClient.get(
      path,
      queryParameters: {
        'page': page,
        if (from != null) 'from': from.toIso8601String().split('T')[0],
        if (to != null) 'to': to.toIso8601String().split('T')[0],
      },
    );

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<PaymentSummary> getSummary({required String month}) async {
    final response = await _apiClient.get(
      '/api/v1/admin/payments/summary',
      queryParameters: {
        'month': month, // YYYY-MM
      },
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => PaymentSummary.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<Payment> record({
    required String memberId,
    required String subscriptionId,
    required double amount,
    required String method,
    DateTime? paidAt,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/admin/payments',
      data: {
        'member_id': memberId,
        'subscription_id': subscriptionId,
        'amount': amount,
        'method': method,
        if (paidAt != null) 'paid_at': paidAt.toIso8601String(),
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Payment.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
