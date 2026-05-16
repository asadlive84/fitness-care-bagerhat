import 'package:fitness_care_bagerhat/core/api/api_exception.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'messages_controller.freezed.dart';

@freezed
class MessagesState with _$MessagesState {
  const factory MessagesState({
    @Default([]) List<ConversationSummary> conversations,
    @Default(false) bool isLoading,
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
      state = state.copyWith(conversations: [], isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _repository.listConversations();
      final conversations = response.data ?? [];

      state = state.copyWith(
        isLoading: false,
        conversations: conversations,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> broadcast(String content, String filter) async {
    try {
      await _repository.sendBroadcast(content: content, filter: filter);
      await load(refresh: true);
    } on ApiException catch (e) {
      state = state.copyWith(error: e);
    }
  }
}

final messagesControllerProvider =
    StateNotifierProvider.autoDispose<MessagesController, MessagesState>((ref) {
  return MessagesController(repository: ref.watch(messageRepositoryProvider));
});
