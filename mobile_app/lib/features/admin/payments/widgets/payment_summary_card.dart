import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/payment.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({required this.summary, super.key});
  final PaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAll24,
      decoration: BoxDecoration(
        gradient: AppColors.gradientOrange,
        borderRadius: AppSpacing.r24,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Month',
                style: AppText.labelLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Icon(PhosphorIcons.chartLineUp(), color: Colors.white),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '৳ ${summary.totalAmount}',
            style: AppText.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${summary.paymentCount} Transactions',
            style: AppText.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Period: ${summary.month}',
            style: AppText.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
