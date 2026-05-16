import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messages_controller.freezed.dart';

@freezed
class MessagesState with _$MessagesState {
  const factory MessagesState({
    @Default([]) List<Message> history,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(1) int page,
    @Default(false) bool hasMore,
    ApiException? error,
  }) = _MessagesState;
}

class MessagesController extends StateNotifier<MessagesState> {
  MessagesController({required MessageRepository repository})
      : _repository = repository,
        super(const MessagesState()) {
    load();
  }

  final MessageRepository _repository;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, history: [], isLoading: true, error: null);
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
      final response = await _repository.list(page: state.page);
      final newMessages = response.data ?? [];
      final hasMore = response.meta?.hasMore ?? false;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        history: refresh ? newMessages : [...state.history, ...newMessages],
        hasMore: hasMore,
        page: state.page + 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e);
    }
  }
}

final messagesControllerProvider =
    StateNotifierProvider.autoDispose<MessagesController, MessagesState>((ref) {
  return MessagesController(repository: ref.watch(messageRepositoryProvider));
});
