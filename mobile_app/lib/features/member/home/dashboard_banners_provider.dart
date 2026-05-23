import 'package:fitness_care_bagerhat/features/member/messages/chat_message.dart';
import 'package:fitness_care_bagerhat/features/member/messages/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardBannersNotifier extends StateNotifier<List<ChatMessage>> {
  DashboardBannersNotifier(this._repo) : super([]) {
    load();
  }

  final ChatRepository _repo;

  Future<void> load() async {
    try {
      final messages = await _repo.getMessages();
      final adminMessages = messages.where((m) => m.senderRole == 'admin').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first

      final banners = <ChatMessage>[];

      // Last direct message
      final lastDirect = adminMessages.where((m) => !m.isBroadcast).firstOrNull;
      if (lastDirect != null) banners.add(lastDirect);

      // Last broadcast/push
      final lastBroadcast = adminMessages.where((m) => m.isBroadcast).firstOrNull;
      if (lastBroadcast != null) banners.add(lastBroadcast);

      state = banners;
    } catch (_) {}
  }

  void dismiss(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final dashboardBannersProvider =
    StateNotifierProvider.autoDispose<DashboardBannersNotifier, List<ChatMessage>>(
  (ref) => DashboardBannersNotifier(ref.watch(chatRepositoryProvider)),
);
