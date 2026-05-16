import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_state.dart';
import 'package:fitness_care_bagerhat/features/member/home/widgets/member_home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          _Greeting(name: data.member.name),
          const SizedBox(height: AppSpacing.s24),
          _SubscriptionHero(member: data.member),
          const SizedBox(height: AppSpacing.s24),
          Text('Your Progress', style: AppText.titleMedium),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              MemberStatMini(
                label: 'Weight',
                value: '72.5', // Placeholder
                unit: 'kg',
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s12),
              MemberStatMini(
                label: 'Workouts',
                value: data.totalWorkouts.toString(),
                unit: 'total',
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.s12),
              MemberStatMini(
                label: 'Streak',
                value: data.currentStreak.toString(),
                unit: 'days',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          _QuickActions(),
          const SizedBox(height: AppSpacing.s24),
          if (data.weightTrend.isNotEmpty)
            WeightMiniChart(data: data.weightTrend),
          const SizedBox(height: AppSpacing.s32),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String name;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Assalamu Alaikum';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting,', style: AppText.headlineMedium),
        Text(
          '$name 🌿',
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

class _SubscriptionHero extends StatelessWidget {
  const _SubscriptionHero({required this.member});
  final dynamic member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAll24,
      decoration: BoxDecoration(
        gradient: AppColors.gradientGreen,
        borderRadius: AppSpacing.r24,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
                'Active Subscription',
                style: AppText.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Icon(PhosphorIcons.crown(), color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            member.planName ?? 'Standard Plan',
            style: AppText.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.s20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65, // Placeholder
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: AppColors.accent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            '21 days left until renewal',
            style: AppText.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            label: 'Log Workout',
            icon: PhosphorIcons.barbell(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _ActionChip(
            label: 'Log Diet',
            icon: PhosphorIcons.bowlFood(),
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.r12,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppText.labelMedium.copyWith(color: color),
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
