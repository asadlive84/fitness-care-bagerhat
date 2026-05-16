import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberDetailController extends StateNotifier<AsyncValue<Member>> {
  MemberDetailController({
    required String memberId,
    required MemberRepository repository,
  })  : _memberId = memberId,
        _repository = repository,
        super(const AsyncValue.loading()) {
    load();
  }

  final String _memberId;
  final MemberRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final member = await _repository.get(_memberId);
      state = AsyncValue.data(member);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleStatus() async {
    final current = state.value;
    if (current == null) return;

    try {
      final currentStatus = state.value!.status;
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      await _repository.updateStatus(_memberId, newStatus);
      await load();
    } catch (e, stack) {
      // In a real app, show a snackbar
      state = AsyncValue.error(e, stack);
    }
  }
}

final memberDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<MemberDetailController, AsyncValue<Member>, String>(
  (ref, id) => MemberDetailController(
    memberId: id,
    repository: ref.watch(memberRepositoryProvider),
  ),
);
