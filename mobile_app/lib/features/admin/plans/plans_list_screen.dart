import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_badge.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_bottom_sheet.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plan.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/plans_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/plans/widgets/plan_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
                  onRetry: () =>
                      ref.read(plansControllerProvider.notifier).load(),
                )
              : state.plans.isEmpty
                  ? GymEmptyState(
                      message: 'No plans yet. Tap + to create the first one.',
                      animationPath: 'assets/animations/empty_members.json',
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
                          onEdit: () => _showPlanForm(context, plan: plan),
                          onDelete: () => _confirmDelete(context, ref, plan),
                        );
                      },
                    ),
    );
  }

  void _showPlanForm(BuildContext context, {Plan? plan}) {
    GymBottomSheet.show<void>(
      context: context,
      title: plan == null ? 'New Plan' : 'Edit Plan',
      child: PlanForm(plan: plan),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Plan plan) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Delete "${plan.name}"? This cannot be undone.\n\n'
          'Plans that are linked to active subscriptions cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await ref
                  .read(plansControllerProvider.notifier)
                  .deletePlan(plan.id);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  final Plan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      onTap: onEdit,
      padding: AppSpacing.paddingAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name, style: AppText.titleLarge),
              ),
              if (plan.memberCount != null) ...[
                GymBadge.custom(
                  label: '${plan.memberCount} Members',
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
              GymBadge.custom(label: 'Standard', color: AppColors.success),
              const SizedBox(width: AppSpacing.s8),
              // Delete button
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.r8,
                  ),
                  child: Icon(
                    PhosphorIcons.trash(),
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price', style: AppText.labelSmall),
                  Text(
                    plan.defaultPrice.toBDT(),
                    style:
                        AppText.titleMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Duration', style: AppText.labelSmall),
                  Text(
                    '${plan.durationDays} days',
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
