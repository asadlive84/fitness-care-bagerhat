import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    @JsonKey(name: 'sender_role') required String senderRole, // 'admin' or 'member'
    @JsonKey(name: 'sent_at') required DateTime createdAt,
    @JsonKey(name: 'is_broadcast') @Default(false) bool isBroadcast,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
