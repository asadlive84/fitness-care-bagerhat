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

  Future<ApiResponse<List<Message>>> list({int page = 1}) async {
    final response = await _apiClient.get(
      '/api/v1/messages',
      queryParameters: {'page': page},
    );

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> send({
    required String type,
    required String content,
    List<String>? memberIds, // null means bulk to all
  }) async {
    await _apiClient.post(
      '/api/v1/messages/send',
      data: {
        'type': type,
        'content': content,
        if (memberIds != null) 'member_ids': memberIds,
      },
    );
  }
}
