import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
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
      body: state.isLoading && state.summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.summary != null)
                    PaymentSummaryCard(summary: state.summary!),
                  const SizedBox(height: AppSpacing.s32),
                  Text('Payment History', style: AppText.titleMedium),
                  const SizedBox(height: AppSpacing.s12),
                  Container(
                    padding: AppSpacing.paddingAll16,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.r12,
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.info(), color: AppColors.info),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Text(
                            "Individual payment history is managed per member. Please visit a Member's profile to view their specific payments.",
                            style: AppText.bodyMedium.copyWith(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
