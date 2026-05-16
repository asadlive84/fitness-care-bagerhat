import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_home_state.freezed.dart';
part 'member_home_state.g.dart';

@freezed
class MemberHomeState with _$MemberHomeState {
  const factory MemberHomeState({
    required Member member,
    MemberSubscription? activeSubscription,
    required List<ChartPoint> weightTrend,
    @Default(0) int totalWorkouts,
    @Default(0) int currentStreak,
    @Default(false) bool isLoading,
  }) = _MemberHomeState;

  factory MemberHomeState.fromJson(Map<String, dynamic> json) =>
      _$MemberHomeStateFromJson(json);
}
