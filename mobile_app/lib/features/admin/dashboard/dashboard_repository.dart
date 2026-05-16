import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    memberRepo: ref.watch(memberRepositoryProvider),
    paymentRepo: ref.watch(paymentRepositoryProvider),
  );
});

class DashboardRepository {
  final MemberRepository _memberRepo;
  final PaymentRepository _paymentRepo;

  DashboardRepository({
    required MemberRepository memberRepo,
    required PaymentRepository paymentRepo,
  })  : _memberRepo = memberRepo,
        _paymentRepo = paymentRepo;

  Future<DashboardStats> getStats() async {
    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Fetch in parallel with explicit return types so the compiler can verify.
    final allMembersResponse = await _memberRepo.list(status: 'all');
    final activeMembersResponse = await _memberRepo.list(status: 'active');
    final paymentSummary = await _paymentRepo.getSummary(month: monthStr);

    return DashboardStats(
      totalMembers: allMembersResponse.meta?.total ??
          allMembersResponse.data?.length ?? 0,
      activeMembers: activeMembersResponse.meta?.total ??
          activeMembersResponse.data?.length ?? 0,
      pendingPayments: 0,
      monthlyRevenue: paymentSummary.totalAmount,
      revenueChart: [],
    );
  }
}
