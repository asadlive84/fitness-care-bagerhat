import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_state.dart';
import 'package:fitness_care_bagerhat/features/member/home/widgets/member_home_widgets.dart';
import 'package:fitness_care_bagerhat/features/member/payments/member_payment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberHomeControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(memberHomeControllerProvider.notifier).load(),
        child: SafeArea(
          child: state.when(
            loading: () => const _LoadingState(),
            error: (error, _) => GymErrorState(
              message: error.toString(),
              onRetry: () => ref.read(memberHomeControllerProvider.notifier).load(),
            ),
            data: (data) => _Content(data: data),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});
  final MemberHomeState data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Greeting(member: data.member),
          const SizedBox(height: AppSpacing.s24),
          _SubscriptionHero(subscription: data.activeSubscription),
          const SizedBox(height: AppSpacing.s24),
          
          Text('Health Insights', style: AppText.titleMedium),
          const SizedBox(height: AppSpacing.s16),
          if (data.member.bmi != null) ...[
            BmiVisualizer(member: data.member),
            const SizedBox(height: AppSpacing.s16),
          ],
          
          if (data.weightTrend.isNotEmpty) ...[
            WeightJourneyTracker(data: data.weightTrend),
            const SizedBox(height: AppSpacing.s24),
          ],

          Text('Quick Stats', style: AppText.titleMedium),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              MemberStatMini(
                label: 'Weight',
                value: (data.member.currentWeight ?? 0).toString(),
                unit: 'kg',
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s12),
              MemberStatMini(
                label: 'Height',
                value: data.member.heightDisplay,
                unit: '',
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.s12),
              MemberStatMini(
                label: 'Age',
                value: (data.member.age == null || data.member.age == 0)
                    ? 'N/A'
                    : data.member.age.toString(),
                unit: (data.member.age == null || data.member.age == 0)
                    ? ''
                    : 'years',
                color: AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s32),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.member});
  final Member member;

  String get _greeting {
    final religion = member.religion?.toLowerCase() ?? '';
    if (religion.contains('islam') || religion.contains('muslim')) {
      return 'Assalamu Alaikum';
    }
    
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Welcome';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting,', style: AppText.headlineMedium),
        Text(
          '${member.name} 🌿',
          style: AppText.headlineMedium.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          DateTime.now().toDisplay(),
          style: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SubscriptionHero extends ConsumerWidget {
  const _SubscriptionHero({required this.subscription});
  final MemberSubscription? subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subscription == null) {
      return Container(
        width: double.infinity,
        padding: AppSpacing.paddingAll24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.r24,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(PhosphorIcons.handWaving(), color: AppColors.primary, size: 40),
            const SizedBox(height: AppSpacing.s12),
            Text('Welcome to Fitness Care!', style: AppText.titleMedium),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Visit the gym office to activate your membership plan.',
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final sub = subscription!;
    final paidAsync = ref.watch(memberActiveSubPaidProvider);
    final total = sub.finalPrice;
    final paid = paidAsync.valueOrNull ?? 0.0;
    final due = total - paid;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final isFullyPaid = due <= 0;

    final durationDays = sub.endDate.difference(sub.startDate).inDays;
    final durationText = durationDays >= 28
        ? '${(durationDays / 30).round()} Month${(durationDays / 30).round() > 1 ? 's' : ''}'
        : '$durationDays Days';

    return GestureDetector(
      onTap: () => context.push(Routes.memberPayments),
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingAll24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.r24,
          border: Border.all(
            color: isFullyPaid ? AppColors.success.withValues(alpha: 0.3) : AppColors.divider,
            width: isFullyPaid ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.note ?? 'Membership Plan',
                        style: AppText.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$durationText Plan · Exp ${sub.endDate.toDisplay()}',
                        style: AppText.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  total.toBDT(),
                  style: AppText.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            ClipRRect(
              borderRadius: AppSpacing.rFull,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.divider.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation(
                  isFullyPaid ? AppColors.success : AppColors.accent,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MinimalStat(label: 'PAID', value: paid.toBDT(), color: AppColors.success),
                _MinimalStat(
                  label: 'DUE',
                  value: (due < 0 ? 0 : due).toBDT(),
                  color: isFullyPaid ? AppColors.textHint : AppColors.error,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalStat extends StatelessWidget {
  const _MinimalStat({
    required this.label,
    required this.value,
    required this.color,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: AppText.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          GymShimmer.line(height: 80),
          SizedBox(height: AppSpacing.s24),
          GymShimmer.card(height: 160),
          SizedBox(height: AppSpacing.s24),
          Row(
            children: [
              Expanded(child: GymShimmer.card(height: 80)),
              SizedBox(width: AppSpacing.s12),
              Expanded(child: GymShimmer.card(height: 80)),
              SizedBox(width: AppSpacing.s12),
              Expanded(child: GymShimmer.card(height: 80)),
            ],
          ),
        ],
      ),
    );
  }
}
