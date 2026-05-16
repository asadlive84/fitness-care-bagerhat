import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plans_controller.freezed.dart';

@freezed
class PlansState with _$PlansState {
  const factory PlansState({
    @Default([]) List<Plan> plans,
    @Default(false) bool isLoading,
    ApiException? error,
  }) = _PlansState;
}

class PlansController extends StateNotifier<PlansState> {
  PlansController({required PlanRepository repository})
      : _repository = repository,
        super(const PlansState()) {
    load();
  }

  final PlanRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.list();
      state = state.copyWith(isLoading: false, plans: response.data ?? []);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> deletePlan(String id) async {
    try {
      await _repository.delete(id);
      load();
    } catch (e) {
      // Handle error
    }
  }
}

final plansControllerProvider =
    StateNotifierProvider.autoDispose<PlansController, PlansState>((ref) {
  return PlansController(repository: ref.watch(planRepositoryProvider));
});
