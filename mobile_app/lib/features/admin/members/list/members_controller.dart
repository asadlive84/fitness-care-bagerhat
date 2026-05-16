import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'members_controller.freezed.dart';

@freezed
class MembersState with _$MembersState {
  const factory MembersState({
    @Default([]) List<Member> members,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(1) int page,
    @Default(false) bool hasMore,
    ApiException? error,
    @Default('') String searchQuery,
    @Default('all') String statusFilter,
  }) = _MembersState;
}

class MembersController extends StateNotifier<MembersState> {
  MembersController({required MemberRepository repository})
      : _repository = repository,
        super(const MembersState()) {
    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen(_onSearchDebounced);
    load();
  }

  final MemberRepository _repository;
  final _searchSubject = PublishSubject<String>();

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, members: [], isLoading: true, error: null);
    } else if (state.isLoadingMore || (state.page > 1 && !state.hasMore)) {
      return;
    } else {
      state = state.copyWith(
        isLoading: state.page == 1,
        isLoadingMore: state.page > 1,
        error: null,
      );
    }

    try {
      final response = await _repository.list(
        page: state.page,
        search: state.searchQuery,
        status: state.statusFilter,
      );

      final newMembers = response.data ?? [];
      final hasMore = response.meta?.hasMore ?? false;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        members: refresh ? newMembers : [...state.members, ...newMembers],
        hasMore: hasMore,
        page: state.page + 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e,
      );
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _searchSubject.add(query);
  }

  void _onSearchDebounced(String query) {
    load(refresh: true);
  }

  void setFilter(String status) {
    if (state.statusFilter == status) return;
    state = state.copyWith(statusFilter: status);
    load(refresh: true);
  }

  @override
  void dispose() {
    _searchSubject.close();
    super.dispose();
  }
}

final membersControllerProvider =
    StateNotifierProvider.autoDispose<MembersController, MembersState>((ref) {
  return MembersController(repository: ref.watch(memberRepositoryProvider));
});
