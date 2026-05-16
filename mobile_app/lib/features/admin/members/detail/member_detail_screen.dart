import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_shadows.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_avatar.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_badge.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_button.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_bottom_sheet.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/member_detail_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/members/detail/widgets/assign_plan_sheet.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/admin/messages/widgets/compose_message_sheet.dart';
import 'package:fitness_care_bagerhat/features/admin/payments/widgets/record_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## MemberDetailScreen
///
/// Admin view showing detailed information about a member.
class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({
    required this.id,
    super.key,
  });

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberDetailControllerProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.pencilSimple()),
            onPressed: () {
              // Navigate to edit
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.dotsThreeVertical()),
            onPressed: () {
              // Show options
            },
          ),
        ],
      ),
      body: state.when(
        loading: () => const _LoadingState(),
        error: (error, _) => GymErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(memberDetailControllerProvider(id).notifier).load(),
        ),
        data: (member) => _Content(member: member),
      ),
    );
  }

  void _showAssignPlan(BuildContext context, WidgetRef ref) {
    GymBottomSheet.show(
      context: context,
      title: 'Assign Membership Plan',
      child: AssignPlanSheet(memberId: id),
    ).then((result) {
      if (result == true) {
        ref.read(memberDetailControllerProvider(id).notifier).load();
      }
    });
  }

  void _showRecordPayment(BuildContext context, WidgetRef ref, Member member) {
    GymBottomSheet.show(
      context: context,
      title: 'Record Payment',
      child: RecordPaymentSheet(
        memberId: member.id,
        memberName: member.name,
        subscriptionId: member.activeSubscription?.id ?? '',
      ),
    ).then((result) {
      if (result == true) {
        ref.read(memberDetailControllerProvider(id).notifier).load();
      }
    });
  }

  void _showSendMessage(BuildContext context, WidgetRef ref, Member member) {
    GymBottomSheet.show(
      context: context,
      title: 'Send Message',
      child: ComposeMessageSheet(initialRecipient: member),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = context.findAncestorWidgetOfExactType<MemberDetailScreen>();

    return SingleChildScrollView(
      padding: AppSpacing.paddingAll24,
      child: Column(
        children: [
          // Header Info
          GymAvatar(
            name: member.name,
            imageUrl: member.imageUrl,
            size: 100,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            member.name,
            style: AppText.headlineLarge,
          ),
          Text(
            member.phone,
            style: AppText.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s8),
          GymBadge.status(status: member.status),
          const SizedBox(height: AppSpacing.s32),

          // Active Subscription Card
          if (member.activeSubscription != null)
            _SubscriptionCard(subscription: member.activeSubscription!)
          else
            GymCard(
              padding: EdgeInsets.all(AppSpacing.s24),
              child: Column(
                children: [
                  Icon(
                    PhosphorIcons.warningCircle(),
                    size: 40,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'No active subscription',
                    style: AppText.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  GymButton.primary(
                    label: 'Assign Plan',
                    onPressed: () => screen?._showAssignPlan(context, ref),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.s24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GymButton.secondary(
                  label: 'Record Payment',
                  icon: Icon(PhosphorIcons.money()),
                  onPressed: () => screen?._showRecordPayment(context, ref, member),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: GymButton.secondary(
                  label: 'Send Message',
                  icon: Icon(PhosphorIcons.chatTeardropDots()),
                  onPressed: () => screen?._showSendMessage(context, ref, member),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s32),

          // Details Section
          _DetailRow(
            icon: PhosphorIcons.calendar(),
            label: 'Member Since',
            value: member.joinDate?.toDisplay() ?? 'N/A',
          ),
          const Divider(height: AppSpacing.s32),
          _DetailRow(
            icon: PhosphorIcons.scales(),
            label: 'Current Weight',
            value: '${member.currentWeight ?? "-"} kg',
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});
  final MemberSubscription subscription;

  @override
  Widget build(BuildContext context) {
    // Progress calculation based on dates since totalDays/daysLeft are no longer in model
    final total = subscription.endDate.difference(subscription.startDate).inDays;
    final used = DateTime.now().difference(subscription.startDate).inDays;
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAll24,
      decoration: BoxDecoration(
        gradient: AppColors.gradientGreen,
        borderRadius: AppSpacing.r24,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscription ID: ${subscription.id.substring(0, 8)}',
                style: AppText.titleLarge.copyWith(color: Colors.white),
              ),
              Icon(PhosphorIcons.clipboardText(), color: Colors.white),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Started ${subscription.startDate.toDisplay()} · Ends ${subscription.endDate.toDisplay()}',
            style: AppText.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            borderRadius: AppSpacing.rFull,
            minHeight: 8,
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${subscription.endDate.difference(DateTime.now()).inDays} days left',
                style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '৳ ${subscription.finalPrice}',
                style: AppText.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.r8,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.s16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.labelSmall),
            Text(value, style: AppText.titleMedium),
          ],
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingAll24,
      child: Column(
        children: [
          const GymShimmer.avatar(size: 100),
          const SizedBox(height: AppSpacing.s16),
          const GymShimmer.line(width: 150, height: 24),
          const SizedBox(height: AppSpacing.s8),
          const GymShimmer.line(width: 100),
          const SizedBox(height: AppSpacing.s32),
          const GymShimmer.card(height: 180),
          const SizedBox(height: AppSpacing.s24),
          Row(
            children: [
              Expanded(child: const GymShimmer.card(height: 48)),
              const SizedBox(width: AppSpacing.s12),
              Expanded(child: const GymShimmer.card(height: 48)),
            ],
          ),
        ],
      ),
    );
  }
}
