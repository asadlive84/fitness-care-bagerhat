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
      final subscription = await _repository.getActiveSubscription();
      
      state = AsyncValue.data(MemberHomeState(
        member: profile,
        activeSubscription: subscription,
        weightTrend: [], // Fetch from weight repository if needed
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
