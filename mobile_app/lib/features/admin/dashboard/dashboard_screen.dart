import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_controller.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/widgets/attendance_chart.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/widgets/revenue_chart.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.bell()),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).load(),
        child: state.when(
          loading: () => const _LoadingState(),
          error: (error, _) => GymErrorState(
            message: error.toString(),
            onRetry: () => ref.read(dashboardControllerProvider.notifier).load(),
          ),
          data: (stats) => _Content(stats: stats),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingAll16,
      child: Column(
        children: [
          // Stat Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.s12,
            crossAxisSpacing: AppSpacing.s12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                label: 'Total Members',
                value: stats.totalMembers.toString(),
                icon: PhosphorIcons.users(),
                color: AppColors.primary,
                trend: '+12%',
              ),
              StatCard(
                label: 'Active Plans',
                value: stats.activeMembers.toString(),
                icon: PhosphorIcons.clipboardText(),
                color: AppColors.info,
              ),
              StatCard(
                label: 'Today Attend',
                value: '42', // Placeholder until API supports today's count
                icon: PhosphorIcons.calendarCheck(),
                color: AppColors.success,
              ),
              StatCard(
                label: 'Due Payments',
                value: stats.pendingPayments.toString(),
                icon: PhosphorIcons.warningCircle(),
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),

          // Charts
          Container(
            padding: AppSpacing.paddingAll20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.r24,
              border: Border.all(color: AppColors.divider),
            ),
            child: RevenueChart(data: stats.revenueChart),
          ),
          const SizedBox(height: AppSpacing.s20),
          Container(
            padding: AppSpacing.paddingAll20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.r24,
              border: Border.all(color: AppColors.divider),
            ),
            child: AttendanceChart(data: stats.attendanceChart),
          ),
          const SizedBox(height: AppSpacing.s32),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingAll16,
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.s12,
            crossAxisSpacing: AppSpacing.s12,
            childAspectRatio: 1.4,
            children: const [
              GymShimmer.card(height: 100),
              GymShimmer.card(height: 100),
              GymShimmer.card(height: 100),
              GymShimmer.card(height: 100),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          const GymShimmer.card(height: 250),
          const SizedBox(height: AppSpacing.s20),
          const GymShimmer.card(height: 250),
        ],
      ),
    );
  }
}
