import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment_repository.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    memberRepo: ref.watch(memberRepositoryProvider),
    paymentRepo: ref.watch(paymentRepositoryProvider),
    planRepo: ref.watch(planRepositoryProvider),
  );
});

class DashboardRepository {
  final MemberRepository _memberRepo;
  final PaymentRepository _paymentRepo;
  final PlanRepository _planRepo;

  DashboardRepository({
    required MemberRepository memberRepo,
    required PaymentRepository paymentRepo,
    required PlanRepository planRepo,
  })  : _memberRepo = memberRepo,
        _paymentRepo = paymentRepo,
        _planRepo = planRepo;

  Future<DashboardStats> getStats() async {
    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Fetch in parallel with explicit return types so the compiler can verify.
    final allMembersResponse = await _memberRepo.list(status: 'all');
    final plansResponse = await _planRepo.list();
    final paymentSummary = await _paymentRepo.getSummary(month: monthStr);

    int dueCount = 0;
    for (final planWrapper in plansResponse.plans) {
      for (final sub in planWrapper.subscribers) {
        if (sub.moneyLeft > 0) {
          dueCount++;
        }
      }
    }

    return DashboardStats(
      totalMembers: allMembersResponse.meta?.total ??
          allMembersResponse.data?.length ?? 0,
      activePlans: plansResponse.plans.length,
      pendingPayments: dueCount,
      monthlyRevenue: paymentSummary.totalAmount,
      revenueChart: [],
    );
  }
}
