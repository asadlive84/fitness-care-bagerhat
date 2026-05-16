import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(apiClient: ref.watch(apiClientProvider));
});

class MessageRepository {
  final ApiClient _apiClient;

  MessageRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ApiResponse<List<ConversationSummary>>> listConversations() async {
    final response = await _apiClient.get('/api/v1/admin/messages/conversations');

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<Message>>> getConversation(String memberId) async {
    final response = await _apiClient.get('/api/v1/admin/messages/conversations/$memberId');

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> sendBroadcast({
    required String content,
    String filter = 'all',
  }) async {
    await _apiClient.post(
      '/api/v1/admin/messages/broadcast',
      data: {
        'content': content,
        'filter': filter,
      },
    );
  }

  Future<void> sendDirect({
    required String memberId,
    required String content,
  }) async {
    await _apiClient.post(
      '/api/v1/admin/messages/direct',
      data: {
        'member_id': memberId,
        'content': content,
      },
    );
  }
}
