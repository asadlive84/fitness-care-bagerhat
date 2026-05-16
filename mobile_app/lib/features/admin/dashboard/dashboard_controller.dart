import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardController extends StateNotifier<AsyncValue<DashboardStats>> {
  DashboardController({required DashboardRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading()) {
    load();
  }

  final DashboardRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getStats();
      state = AsyncValue.data(stats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final dashboardControllerProvider = StateNotifierProvider.autoDispose<
    DashboardController, AsyncValue<DashboardStats>>((ref) {
  return DashboardController(repository: ref.watch(dashboardRepositoryProvider));
});
