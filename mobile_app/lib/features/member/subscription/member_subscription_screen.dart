import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_empty_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## MemberSubscriptionScreen
///
/// Member's dedicated view of their active subscription with full details.
class MemberSubscriptionScreen extends ConsumerWidget {
  const MemberSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberHomeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscription')),
      body: state.when(
        loading: () => const _LoadingState(),
        error: (e, _) => GymErrorState(
          message: e.toString(),
          onRetry: () => ref.read(memberHomeControllerProvider.notifier).load(),
        ),
        data: (data) {
          final sub = data.activeSubscription;
          if (sub == null) {
            return const GymEmptyState(
              message: 'You have no active subscription.\nVisit the gym office to get started.',
              animationPath: 'assets/animations/empty_members.json',
            );
          }
          return _Content(subscription: sub);
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.subscription});
  final MemberSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final total =
        subscription.endDate.difference(subscription.startDate).inDays;
    final used = DateTime.now().difference(subscription.startDate).inDays;
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final daysLeft = subscription.endDate.difference(DateTime.now()).inDays;
    final isExpiring = daysLeft < 7;

    return SingleChildScrollView(
      padding: AppSpacing.paddingAll20,
      child: Column(
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingAll24,
            decoration: BoxDecoration(
              gradient:
                  isExpiring ? AppColors.gradientOrange : AppColors.gradientGreen,
              borderRadius: AppSpacing.r24,
              boxShadow: [
                BoxShadow(
                  color: (isExpiring ? AppColors.accent : AppColors.primary)
                      .withValues(alpha: 0.3),
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
                      'Active Plan',
                      style: AppText.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Icon(PhosphorIcons.crown(), color: Colors.white, size: 22),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  subscription.note ?? 'Membership Plan',
                  style: AppText.titleLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  subscription.finalPrice.toBDT(),
                  style: AppText.monoLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.s24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isExpiring
                          ? '⚠️ Expires soon!'
                          : '$daysLeft days remaining',
                      style: AppText.labelSmall
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      '${(progress * 100).round()}% used',
                      style: AppText.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s32),

          // Details card
          _DetailsCard(subscription: subscription),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.subscription});
  final MemberSubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAll20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.r20,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscription Details', style: AppText.titleMedium),
          const SizedBox(height: AppSpacing.s20),
          _Row(label: 'Status', value: subscription.status.toUpperCase()),
          const Divider(height: AppSpacing.s32),
          _Row(
              label: 'Start Date',
              value: subscription.startDate.toDisplay()),
          const Divider(height: AppSpacing.s32),
          _Row(
              label: 'End Date', value: subscription.endDate.toDisplay()),
          const Divider(height: AppSpacing.s32),
          _Row(
            label: 'Amount Paid',
            value: '৳ ${subscription.finalPrice.toBDT()}',
          ),
          if (subscription.note != null && subscription.note!.isNotEmpty) ...[
            const Divider(height: AppSpacing.s32),
            _Row(label: 'Note', value: subscription.note!),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppText.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppText.titleSmall),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: AppSpacing.paddingAll20,
      child: Column(
        children: [
          GymShimmer.card(height: 200),
          SizedBox(height: AppSpacing.s32),
          GymShimmer.card(height: 280),
        ],
      ),
    );
  }
}
