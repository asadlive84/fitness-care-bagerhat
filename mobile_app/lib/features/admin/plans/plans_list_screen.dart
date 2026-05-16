import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_badge.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fitness_care_bagerhat/core/widgets/gym_bottom_sheet.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/widgets/plan_form.dart';

class PlansListScreen extends ConsumerWidget {
  const PlansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plansControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Plans'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.plus()),
            onPressed: () => _showPlanForm(context),
          ),
        ],
      ),
      body: state.isLoading
          ? ListView.separated(
              padding: AppSpacing.paddingAll16,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
              itemBuilder: (_, __) => const GymShimmer.card(height: 100),
            )
          : state.error != null
              ? GymErrorState(
                  message: state.error!.message,
                  onRetry: () => ref.read(plansControllerProvider.notifier).load(),
                )
              : state.plans.isEmpty
                  ? GymEmptyState(
                      message: 'No plans created yet.',
                      animationPath: 'assets/animations/empty_plans.json',
                      actionLabel: 'Create Plan',
                      onAction: () => _showPlanForm(context),
                    )
                  : ListView.separated(
                      padding: AppSpacing.paddingAll16,
                      itemCount: state.plans.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (context, index) {
                        final plan = state.plans[index];
                        return _PlanCard(
                          plan: plan,
                          onTap: () => _showPlanForm(context, plan: plan),
                        );
                      },
                    ),
    );
  }

  void _showPlanForm(BuildContext context, {Plan? plan}) {
    GymBottomSheet.show(
      context: context,
      title: plan == null ? 'New Plan' : 'Edit Plan',
      child: PlanForm(plan: plan),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onTap});
  final Plan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      onTap: onTap,
      padding: AppSpacing.paddingAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: AppText.titleLarge,
                ),
              ),
              GymBadge.custom(
                label: 'Standard',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Duration: ${plan.durationDays} days',
            style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price', style: AppText.labelSmall),
                  Text(
                    '৳ ${plan.defaultPrice}',
                    style: AppText.titleMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Duration', style: AppText.labelSmall),
                  Text(
                    '${plan.durationDays} Days',
                    style: AppText.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
