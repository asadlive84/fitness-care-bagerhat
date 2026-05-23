import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
part 'dashboard_stats.g.dart';

@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    @JsonKey(name: 'total_members') required int totalMembers,
    @JsonKey(name: 'active_plans') required int activePlans,
    @JsonKey(name: 'pending_payments') required int pendingPayments,
    @JsonKey(name: 'monthly_revenue') required double monthlyRevenue,
    @JsonKey(name: 'revenue_chart') required List<ChartPoint> revenueChart,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
}

@freezed
class ChartPoint with _$ChartPoint {
  const factory ChartPoint({
    required String label,
    required double value,
  }) = _ChartPoint;

  factory ChartPoint.fromJson(Map<String, dynamic> json) =>
      _$ChartPointFromJson(json);
}
