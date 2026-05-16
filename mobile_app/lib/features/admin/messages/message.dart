import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'sender_role') required String senderRole,
    @JsonKey(name: 'receiver_id') String? receiverId,
    @JsonKey(name: 'is_broadcast') required bool isBroadcast,
    @JsonKey(name: 'content') required String content,
    @JsonKey(name: 'sent_at') required DateTime sentAt,
    @JsonKey(name: 'read_at') DateTime? readAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}

@freezed
class ConversationSummary with _$ConversationSummary {
  const factory ConversationSummary({
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'last_message') required String lastMessage,
    @JsonKey(name: 'last_sent_at') required DateTime lastSentAt,
    @JsonKey(name: 'sender_role') required String senderRole,
  }) = _ConversationSummary;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      _$ConversationSummaryFromJson(json);
}
