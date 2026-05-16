import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payments_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/widgets/payment_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.funnel()),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.summary != null)
            Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: PaymentSummaryCard(summary: state.summary!),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: Row(
              children: [
                Text('History', style: AppText.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Expanded(
            child: _buildList(state, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildList(PaymentsState state, WidgetRef ref) {
    if (state.isLoading) {
      return ListView.separated(
        padding: AppSpacing.paddingAll16,
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, __) => const GymShimmer.line(height: 70),
      );
    }

    if (state.error != null) {
      return GymErrorState(
        message: state.error!.message,
        onRetry: () =>
            ref.read(paymentsControllerProvider.notifier).load(refresh: true),
      );
    }

    if (state.payments.isEmpty) {
      return const GymEmptyState(
        message: 'No payments found.',
        animationPath: 'assets/animations/empty_payments.json',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paymentsControllerProvider.notifier).load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: state.payments.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final payment = state.payments[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.s8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.money(),
                color: AppColors.success,
                size: 20,
              ),
            ),
            title: Text('Payment ID: ${payment.id.substring(0, 8)}', style: AppText.titleSmall),
            subtitle: Text(
              '${payment.createdAt.toDisplay()} · ${payment.method}',
              style: AppText.bodySmall,
            ),
            trailing: Text(
              '৳ ${payment.amount}',
              style: AppText.titleMedium.copyWith(color: AppColors.success),
            ),
          );
        },
      ),
    );
  }
}
