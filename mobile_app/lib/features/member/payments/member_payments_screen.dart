import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment.dart';
import 'package:fitness_care_bagerhat/features/member/payments/member_payment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _memberPaymentsProvider =
    StateNotifierProvider.autoDispose<_MemberPaymentsController, AsyncValue<List<Payment>>>(
  (ref) => _MemberPaymentsController(ref.watch(memberPaymentRepositoryProvider)),
);

class _MemberPaymentsController
    extends StateNotifier<AsyncValue<List<Payment>>> {
  _MemberPaymentsController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final MemberPaymentRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repo.list();
      state = AsyncValue.data(response.data ?? []);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// ## MemberPaymentsScreen
///
/// Member's own payment history.
class MemberPaymentsScreen extends ConsumerWidget {
  const MemberPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_memberPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise()),
            onPressed: () => ref.read(_memberPaymentsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const _LoadingState(),
        error: (e, _) => GymErrorState(
          message: e.toString(),
          onRetry: () => ref.read(_memberPaymentsProvider.notifier).load(),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const GymEmptyState(
              message: 'No payment records found.',
              animationPath: 'assets/animations/empty_members.json',
            );
          }

          final total = payments.fold<double>(0, (sum, p) => sum + p.amount);

          return RefreshIndicator(
            onRefresh: () => ref.read(_memberPaymentsProvider.notifier).load(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SummaryCard(total: total, count: payments.length),
                ),
                SliverPadding(
                  padding: AppSpacing.paddingAll16,
                  sliver: SliverList.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.s8),
                    itemBuilder: (context, index) =>
                        _PaymentTile(payment: payments[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.count});
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppSpacing.paddingAll16,
      padding: AppSpacing.paddingAll20,
      decoration: BoxDecoration(
        gradient: AppColors.gradientGreen,
        borderRadius: AppSpacing.r20,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Paid',
                  style: AppText.labelSmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  total.toBDT(),
                  style: AppText.monoLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: AppText.displayMedium.copyWith(color: Colors.white),
              ),
              Text(
                'transactions',
                style: AppText.labelSmall
                    .copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Payment payment;

  Color get _methodColor => switch (payment.method.toLowerCase()) {
        'bkash' => const Color(0xFFE2136E),
        'nagad' => const Color(0xFFFF6000),
        'card' => AppColors.info,
        _ => AppColors.success,
      };

  IconData get _methodIcon => switch (payment.method.toLowerCase()) {
        'bkash' || 'nagad' => Icons.phone_android,
        'card' => Icons.credit_card,
        _ => Icons.payments_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAll16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.r16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _methodColor.withValues(alpha: 0.12),
              borderRadius: AppSpacing.r12,
            ),
            child: Icon(_methodIcon, color: _methodColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.method, style: AppText.titleSmall),
                Text(
                  payment.paidAt.toDisplay(),
                  style: AppText.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            payment.amount.toBDT(),
            style: AppText.titleSmall
                .copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: AppSpacing.paddingAll16,
      child: Column(
        children: [
          GymShimmer.card(height: 100),
          SizedBox(height: AppSpacing.s20),
          GymShimmer.card(height: 72),
          SizedBox(height: AppSpacing.s8),
          GymShimmer.card(height: 72),
          SizedBox(height: AppSpacing.s8),
          GymShimmer.card(height: 72),
          SizedBox(height: AppSpacing.s8),
          GymShimmer.card(height: 72),
        ],
      ),
    );
  }
}
