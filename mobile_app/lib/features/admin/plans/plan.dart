import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan.freezed.dart';
part 'plan.g.dart';

@freezed
class Plan with _$Plan {
  const factory Plan({
    required String id,
    required String name,
    @JsonKey(name: 'default_price') required double defaultPrice,
    @JsonKey(name: 'duration_days') required int durationDays,
    @JsonKey(name: 'member_count') int? memberCount,
    DateTime? createdAt,
  }) = _Plan;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
}
