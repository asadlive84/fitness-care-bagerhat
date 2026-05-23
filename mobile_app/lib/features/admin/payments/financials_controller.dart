import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/financial_models.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/financial_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'financials_controller.freezed.dart';

enum PeriodFilter { thisMonth, prevMonth, custom }

@freezed
class FinancialsState with _$FinancialsState {
  const factory FinancialsState({
    required DateTime currentMonth,
    @Default(PeriodFilter.thisMonth) PeriodFilter selectedPeriod,
    DateTime? customFrom,
    DateTime? customTo,
    @Default([]) List<DailyFinancial> dailyFinancials,
    @Default([]) List<Expense> expenses,
    ExpensesSummary? expensesSummary,
    FinancialsReport? centralReport,
    @Default(false) bool isExpensesLoading,
    @Default(false) bool isExpensesLoadingMore,
    @Default(false) bool isCalendarLoading,
    @Default(false) bool isReportLoading,
    @Default(false) bool isLoggingExpense,
    @Default(1) int expensesPage,
    @Default(false) bool hasMoreExpenses,
    ApiException? error,
  }) = _FinancialsState;
}

class FinancialsController extends StateNotifier<FinancialsState> {
  FinancialsController({
    required FinancialRepository repository,
  })  : _repository = repository,
        super(FinancialsState(currentMonth: DateTime.now())) {
    loadAll();
  }

  final FinancialRepository _repository;

  Future<void> loadAll() async {
    await Future.wait([
      loadCalendar(),
      loadExpensesSummary(),
      loadExpenses(refresh: true),
      loadReport(),
    ]);
  }

  Future<void> loadCalendar() async {
    state = state.copyWith(isCalendarLoading: true, error: null);
    try {
      final monthStr = '${state.currentMonth.year}-${state.currentMonth.month.toString().padLeft(2, '0')}';
      final dailyList = await _repository.getDailyFinancials(month: monthStr);
      state = state.copyWith(
        isCalendarLoading: false,
        dailyFinancials: dailyList,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isCalendarLoading: false, error: e);
    } catch (e) {
      state = state.copyWith(isCalendarLoading: false);
    }
  }

  Future<void> loadExpensesSummary() async {
    try {
      final summary = await _repository.getExpensesSummary();
      state = state.copyWith(expensesSummary: summary);
    } catch (_) {}
  }

  Future<void> loadExpenses({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        expensesPage: 1,
        expenses: [],
        isExpensesLoading: true,
        error: null,
      );
    } else if (state.isExpensesLoadingMore || (state.expensesPage > 1 && !state.hasMoreExpenses)) {
      return;
    } else {
      state = state.copyWith(
        isExpensesLoading: state.expensesPage == 1,
        isExpensesLoadingMore: state.expensesPage > 1,
        error: null,
      );
    }

    try {
      final response = await _repository.listExpenses(page: state.expensesPage);
      final newExpenses = response.data ?? [];
      final hasMore = response.meta?.hasMore ?? false;

      state = state.copyWith(
        isExpensesLoading: false,
        isExpensesLoadingMore: false,
        expenses: refresh ? newExpenses : [...state.expenses, ...newExpenses],
        hasMoreExpenses: hasMore,
        expensesPage: state.expensesPage + 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isExpensesLoading: false,
        isExpensesLoadingMore: false,
        error: e,
      );
    }
  }

  Future<void> loadReport() async {
    state = state.copyWith(isReportLoading: true, error: null);
    try {
      final now = DateTime.now();
      DateTime start;
      DateTime end;

      switch (state.selectedPeriod) {
        case PeriodFilter.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case PeriodFilter.prevMonth:
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case PeriodFilter.custom:
          start = state.customFrom ?? DateTime(now.year, now.month, 1);
          end = state.customTo ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
      }

      final report = await _repository.getCentralReport(from: start, to: end);
      state = state.copyWith(
        isReportLoading: false,
        centralReport: report,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isReportLoading: false, error: e);
    } catch (_) {
      state = state.copyWith(isReportLoading: false);
    }
  }

  Future<void> setPeriod(PeriodFilter filter) async {
    state = state.copyWith(selectedPeriod: filter);
    if (filter != PeriodFilter.custom) {
      await loadReport();
    }
  }

  Future<void> setCustomRange(DateTime from, DateTime to) async {
    state = state.copyWith(
      selectedPeriod: PeriodFilter.custom,
      customFrom: from,
      customTo: to,
    );
    await loadReport();
  }

  Future<void> changeMonth(int monthsDelta) async {
    final nextMonth = DateTime(
      state.currentMonth.year,
      state.currentMonth.month + monthsDelta,
      1,
    );
    state = state.copyWith(currentMonth: nextMonth);
    await loadCalendar();
  }

  Future<bool> logExpense({
    required double amount,
    required String description,
    required String category,
    DateTime? spentAt,
  }) async {
    state = state.copyWith(isLoggingExpense: true, error: null);
    try {
      await _repository.logExpense(
        amount: amount,
        description: description,
        category: category,
        spentAt: spentAt,
      );
      state = state.copyWith(isLoggingExpense: false);
      await loadAll();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoggingExpense: false, error: e);
      return false;
    } catch (_) {
      state = state.copyWith(isLoggingExpense: false);
      return false;
    }
  }
}

final financialsControllerProvider =
    StateNotifierProvider.autoDispose<FinancialsController, FinancialsState>((ref) {
  return FinancialsController(
    repository: ref.watch(financialRepositoryProvider),
  );
});
