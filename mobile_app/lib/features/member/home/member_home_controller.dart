import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_repository.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberHomeController extends StateNotifier<AsyncValue<MemberHomeState>> {
  MemberHomeController({required MemberHomeRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading()) {
    load();
  }

  final MemberHomeRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile();
      
      // Attempt to get subscription, but don't fail if missing (404)
      MemberSubscription? subscription;
      try {
        subscription = await _repository.getActiveSubscription();
      } catch (_) {
        // If 404 or other error, treat as no active subscription
        subscription = null;
      }
      
      List<ChartPoint> weightTrend = [];
      try {
        weightTrend = await _repository.getWeightTrend();
      } catch (_) {
        // Fallback to empty if error
      }
      
      state = AsyncValue.data(MemberHomeState(
        member: profile,
        activeSubscription: subscription,
        weightTrend: weightTrend,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final memberHomeControllerProvider = StateNotifierProvider.autoDispose<
    MemberHomeController, AsyncValue<MemberHomeState>>((ref) {
  return MemberHomeController(
    repository: ref.watch(memberHomeRepositoryProvider),
  );
});
