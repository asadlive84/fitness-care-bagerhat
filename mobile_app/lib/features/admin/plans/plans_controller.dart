import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Period enum ───────────────────────────────────────────────────────────────

enum PlanPeriod { monthly, lifetime, custom }

// ── State ─────────────────────────────────────────────────────────────────────

class PlansState {
  const PlansState({
    this.enrichedPlans = const [],
    this.summary = PlanSummary.zero,
    this.period = PlanPeriod.monthly,
    required this.selectedMonth,
    this.customFrom,
    this.customTo,
    this.isLoading = false,
    this.error,
  });

  final List<PlanWithSubscribers> enrichedPlans;
  final PlanSummary summary;
  final PlanPeriod period;
  final DateTime selectedMonth;   // used when period == monthly
  final DateTime? customFrom;
  final DateTime? customTo;
  final bool isLoading;
  final ApiException? error;

  /// Flat Plan list kept for backward compat with AssignPlanSheet.
  List<Plan> get plans => enrichedPlans.map((p) => p.plan).toList();

  PlansState copyWith({
    List<PlanWithSubscribers>? enrichedPlans,
    PlanSummary? summary,
    PlanPeriod? period,
    DateTime? selectedMonth,
    Object? customFrom = _absent,
    Object? customTo = _absent,
    bool? isLoading,
    Object? error = _absent,
  }) =>
      PlansState(
        enrichedPlans: enrichedPlans ?? this.enrichedPlans,
        summary: summary ?? this.summary,
        period: period ?? this.period,
        selectedMonth: selectedMonth ?? this.selectedMonth,
        customFrom: customFrom == _absent ? this.customFrom : customFrom as DateTime?,
        customTo: customTo == _absent ? this.customTo : customTo as DateTime?,
        isLoading: isLoading ?? this.isLoading,
        error: error == _absent ? this.error : error as ApiException?,
      );
}

const _absent = Object();

// ── Controller ────────────────────────────────────────────────────────────────

class PlansController extends StateNotifier<PlansState> {
  PlansController({required PlanRepository repository})
      : _repository = repository,
        super(PlansState(selectedMonth: _firstOfMonth(DateTime.now()))) {
    load();
  }

  final PlanRepository _repository;

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  /// Reload using the current filter state.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _fetchWithCurrentFilter();
      state = state.copyWith(
        isLoading: false,
        enrichedPlans: resp.plans,
        summary: resp.summary,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<PlansApiResponse> _fetchWithCurrentFilter() {
    switch (state.period) {
      case PlanPeriod.lifetime:
        return _repository.list();
      case PlanPeriod.monthly:
        final m = DateFormat('yyyy-MM').format(state.selectedMonth);
        return _repository.list(month: m);
      case PlanPeriod.custom:
        final from = state.customFrom != null
            ? DateFormat('yyyy-MM-dd').format(state.customFrom!)
            : null;
        final to = state.customTo != null
            ? DateFormat('yyyy-MM-dd').format(state.customTo!)
            : null;
        return _repository.list(from: from, to: to);
    }
  }

  // ── Period controls ────────────────────────────────────────────────────────

  void setPeriod(PlanPeriod period) {
    state = state.copyWith(period: period);
    load();
  }

  /// Navigate to the previous month.
  void prevMonth() {
    final m = state.selectedMonth;
    state = state.copyWith(
      period: PlanPeriod.monthly,
      selectedMonth: DateTime(m.year, m.month - 1, 1),
    );
    load();
  }

  /// Navigate to the next month (capped at current month).
  void nextMonth() {
    final m = state.selectedMonth;
    final next = DateTime(m.year, m.month + 1, 1);
    if (next.isAfter(DateTime.now())) return;
    state = state.copyWith(period: PlanPeriod.monthly, selectedMonth: next);
    load();
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(
      period: PlanPeriod.custom,
      customFrom: from,
      customTo: to,
    );
    load();
  }

  // ── Plan CRUD ──────────────────────────────────────────────────────────────

  Future<String?> deletePlan(String id) async {
    try {
      await _repository.delete(id);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}

final plansControllerProvider =
    StateNotifierProvider.autoDispose<PlansController, PlansState>((ref) {
  return PlansController(repository: ref.watch(planRepositoryProvider));
});
