import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
class Member with _$Member {
  const factory Member({
    required String id,
    required String name,
    required String phone,
    @Default('active') String status,
    @JsonKey(name: 'join_date') DateTime? joinDate,
    @JsonKey(name: 'current_weight') double? currentWeight,
    @JsonKey(name: 'must_change_password') @Default(false) bool mustChangePassword,
    MemberSubscription? activeSubscription,
    String? imageUrl,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}

@freezed
class MemberSubscription with _$MemberSubscription {
  const factory MemberSubscription({
    required String id,
    @JsonKey(name: 'plan_template_id') required String planId,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'final_price') required double finalPrice,
    String? note,
    @Default('active') String status,
  }) = _MemberSubscription;

  factory MemberSubscription.fromJson(Map<String, dynamic> json) =>
      _$MemberSubscriptionFromJson(json);
}
