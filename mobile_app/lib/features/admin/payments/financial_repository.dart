import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/financial_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepository(apiClient: ref.watch(apiClientProvider));
});

class FinancialRepository {
  final ApiClient _apiClient;

  FinancialRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Expense> logExpense({
    required double amount,
    required String description,
    required String category,
    DateTime? spentAt,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/admin/expenses',
      data: {
        'amount': amount,
        'description': description,
        'category': category,
        if (spentAt != null) 'spent_at': spentAt.toUtc().toIso8601String(),
      },
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Expense.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  /// List operation expenses
  Future<ApiResponse<List<Expense>>> listExpenses({
    int page = 1,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/admin/expenses',
      queryParameters: {
        'page': page,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Fetch expense aggregates (Today, Yesterday, Month)
  Future<ExpensesSummary> getExpensesSummary() async {
    final response = await _apiClient.get('/api/v1/admin/expenses/summary');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ExpensesSummary.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  /// Fetch combined daily financials calendar ledger for a month
  Future<List<DailyFinancial>> getDailyFinancials({required String month}) async {
    final response = await _apiClient.get(
      '/api/v1/admin/financials/calendar',
      queryParameters: {
        'month': month, // YYYY-MM
      },
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List).map((e) => DailyFinancial.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return apiResponse.data ?? [];
  }

  /// Fetch centralized financials analytics report over custom dates
  Future<FinancialsReport> getCentralReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/admin/financials/report',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => FinancialsReport.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}

