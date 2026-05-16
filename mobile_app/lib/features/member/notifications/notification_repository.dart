import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(apiClient: ref.watch(apiClientProvider));
});

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> registerFcmToken({
    required String token,
    String? deviceInfo,
  }) async {
    await _apiClient.post(
      '/api/v1/member/fcm-token',
      data: {
        'token': token,
        if (deviceInfo != null) 'device_info': deviceInfo,
      },
    );
  }

  Future<void> setMutePreference({
    required bool muted,
    DateTime? until,
  }) async {
    await _apiClient.patch(
      '/api/v1/member/notifications/mute',
      data: {
        'muted': muted,
        if (until != null) 'until': until.toUtc().toIso8601String(),
      },
    );
  }
}
