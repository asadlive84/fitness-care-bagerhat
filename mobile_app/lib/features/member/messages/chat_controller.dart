import 'package:fitness_care_bagerhat/features/member/messages/chat_message.dart';
import 'package:fitness_care_bagerhat/features/member/messages/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatController({required ChatRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading()) {
    load();
  }

  final ChatRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getMessages();
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> send(String content) async {
    try {
      await _repository.sendMessage(content);
      await load();
    } catch (e) {
      // Handle error
    }
  }
}

final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatController, AsyncValue<List<ChatMessage>>>((ref) {
  return ChatController(repository: ref.watch(chatRepositoryProvider));
});
