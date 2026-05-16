import 'package:fitness_care_bagerhat/core/api/api_client.dart';
import 'package:fitness_care_bagerhat/core/api/api_response.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(apiClient: ref.watch(apiClientProvider));
});

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<DashboardStats> getStats() async {
    // Since backend doesn't have /stats, we return a mock or empty stats for now
    // to avoid crashing. In a real scenario, we'd aggregate from multiple calls.
    return const DashboardStats(
      totalMembers: 0,
      activeMembers: 0,
      pendingPayments: 0,
      monthlyRevenue: 0.0,
      revenueChart: [],
      attendanceChart: [],
    );
  }
}
