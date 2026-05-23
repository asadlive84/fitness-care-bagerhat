import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_models.freezed.dart';
part 'financial_models.g.dart';

@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required double amount,
    required String description,
    required String category,
    @JsonKey(name: 'spent_at') required DateTime spentAt,
    @JsonKey(name: 'recorded_by') required String recordedBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
}

@freezed
class ExpensesSummary with _$ExpensesSummary {
  const factory ExpensesSummary({
    @JsonKey(name: 'today_total') required double todayTotal,
    @JsonKey(name: 'yesterday_total') required double yesterdayTotal,
    @JsonKey(name: 'month_total') required double monthTotal,
  }) = _ExpensesSummary;

  factory ExpensesSummary.fromJson(Map<String, dynamic> json) =>
      _$ExpensesSummaryFromJson(json);
}

@freezed
class DailyFinancial with _$DailyFinancial {
  const factory DailyFinancial({
    required DateTime date,
    required double earnings,
    required double expenses,
    required double net,
  }) = _DailyFinancial;

  factory DailyFinancial.fromJson(Map<String, dynamic> json) =>
      _$DailyFinancialFromJson(json);
}

@freezed
class PlanRevenueBreakdown with _$PlanRevenueBreakdown {
  const factory PlanRevenueBreakdown({
    @JsonKey(name: 'plan_name') required String planName,
    @JsonKey(name: 'plan_price') required double planPrice,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'transaction_count') required int transactionCount,
  }) = _PlanRevenueBreakdown;

  factory PlanRevenueBreakdown.fromJson(Map<String, dynamic> json) =>
      _$PlanRevenueBreakdownFromJson(json);
}

@freezed
class MethodRevenueBreakdown with _$MethodRevenueBreakdown {
  const factory MethodRevenueBreakdown({
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'transaction_count') required int transactionCount,
  }) = _MethodRevenueBreakdown;

  factory MethodRevenueBreakdown.fromJson(Map<String, dynamic> json) =>
      _$MethodRevenueBreakdownFromJson(json);
}

@freezed
class CategoryExpenseBreakdown with _$CategoryExpenseBreakdown {
  const factory CategoryExpenseBreakdown({
    required String category,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'expense_count') required int expenseCount,
  }) = _CategoryExpenseBreakdown;

  factory CategoryExpenseBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategoryExpenseBreakdownFromJson(json);
}

@freezed
class FinancialsReport with _$FinancialsReport {
  const factory FinancialsReport({
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'total_income') required double totalIncome,
    @JsonKey(name: 'total_cost') required double totalCost,
    @JsonKey(name: 'net_profit') required double netProfit,
    required List<DailyFinancial> timeline,
    @JsonKey(name: 'revenue_by_plan') required List<PlanRevenueBreakdown> revenueByPlan,
    @JsonKey(name: 'revenue_by_method') required List<MethodRevenueBreakdown> revenueByMethod,
    @JsonKey(name: 'expenses_by_category') required List<CategoryExpenseBreakdown> expensesByCategory,
  }) = _FinancialsReport;

  factory FinancialsReport.fromJson(Map<String, dynamic> json) =>
      _$FinancialsReportFromJson(json);
}
