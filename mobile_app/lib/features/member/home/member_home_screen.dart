import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/extensions/datetime_ext.dart';
import 'package:fitness_care_bagerhat/core/extensions/num_ext.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_error_state.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_shimmer.dart';
import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fitness_care_bagerhat/features/member/home/dashboard_banners_provider.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_controller.dart';
import 'package:fitness_care_bagerhat/features/member/home/member_home_state.dart';
import 'package:fitness_care_bagerhat/features/member/home/widgets/member_home_widgets.dart';
import 'package:fitness_care_bagerhat/features/member/messages/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

class _Content extends ConsumerWidget {
  const _Content({required this.data});
  final MemberHomeState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(dashboardBannersProvider);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banners.isNotEmpty) ...[
            _MessageBanners(banners: banners, ref: ref),
            const SizedBox(height: AppSpacing.s16),
          ],
          _Greeting(member: data.member),
          const SizedBox(height: AppSpacing.s24),
          _SubscriptionHero(subscription: data.activeSubscription),
          const SizedBox(height: AppSpacing.s24),
          _DietPlanCard(member: data.member),
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
              const SizedBox(width: AppSpacing.s12),
              MemberStatMini(
                label: 'Gender',
                value: data.member.gender,
                unit: '',
                color: AppColors.info,
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

class _SubscriptionHero extends StatelessWidget {
  const _SubscriptionHero({required this.subscription});
  final MemberSubscription? subscription;

  @override
  Widget build(BuildContext context) {
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
    final total = sub.finalPrice;
    final paid = sub.moneyPaid;
    final due = sub.moneyLeft;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final isFullyPaid = due <= 0;
    final isPrepaid = sub.billingType == 'prepaid';

    final planLabel = sub.planName.isNotEmpty ? sub.planName : (sub.note ?? 'Membership Plan');
    final durationDays = sub.endDate.difference(sub.startDate).inDays;
    final remainingDays = sub.endDate.difference(DateTime.now()).inDays;
    
    final durationText = durationDays >= 28
        ? '${(durationDays / 30).round()} Month${(durationDays / 30).round() > 1 ? 's' : ''}'
        : '$durationDays Days';
        
    final remainingText = remainingDays > 0 
        ? '$remainingDays days left' 
        : (remainingDays == 0 ? 'Expires today' : 'Expired');

    final fmt = DateFormat('dd MMM yyyy');

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
            // ── Header row: plan name + billing type badge + amount ──────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planLabel,
                        style: AppText.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$durationText · $remainingText',
                        style: AppText.labelSmall.copyWith(
                          color: remainingDays > 5 ? AppColors.textSecondary : AppColors.error,
                          fontWeight: remainingDays > 5 ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      total.toBDT(),
                      style: AppText.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _BillingBadge(billingType: sub.billingType),
                  ],
                ),
              ],
            ),

            // ── Billing-specific info row ────────────────────────────────
            if (!isFullyPaid) ...[
              const SizedBox(height: AppSpacing.s12),
              _BillingInfoRow(sub: sub, fmt: fmt, isPrepaid: isPrepaid),
            ],

            const SizedBox(height: AppSpacing.s20),

            // ── Progress bar ─────────────────────────────────────────────
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
                  value: due.toBDT(),
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

/// Green Prepaid / Blue Postpaid badge
class _BillingBadge extends StatelessWidget {
  const _BillingBadge({required this.billingType});
  final String billingType;

  @override
  Widget build(BuildContext context) {
    final isPrepaid = billingType == 'prepaid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isPrepaid ? AppColors.success : AppColors.info).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPrepaid ? 'Prepaid' : 'Postpaid',
        style: AppText.labelSmall.copyWith(
          color: isPrepaid ? AppColors.success : AppColors.info,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Billing-specific messaging row shown below the header.
class _BillingInfoRow extends StatelessWidget {
  const _BillingInfoRow({
    required this.sub,
    required this.fmt,
    required this.isPrepaid,
  });
  final MemberSubscription sub;
  final DateFormat fmt;
  final bool isPrepaid;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: AppSpacing.r12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppText.bodySmall.copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _resolve() {
    final days = sub.daysUntilDue;
    switch (sub.billingStatus) {
      case 'prepaid_overdue':
        return (PhosphorIcons.warning(), 'Overdue by ${days?.abs() ?? 0} days', AppColors.error);
      case 'prepaid_due':
        if (sub.prepaidDueDate != null) {
          return (PhosphorIcons.calendarDot(), 'Payment due by ${fmt.format(sub.prepaidDueDate!)}', AppColors.warning);
        }
        return (PhosphorIcons.clock(), 'Due in ${days ?? 0} days', AppColors.warning);
      case 'prepaid_pending':
        return (PhosphorIcons.info(), 'Payment pending', AppColors.textSecondary);
      case 'postpaid_not_due_yet':
        return (PhosphorIcons.clock(), 'Payment window opens in ${days ?? 0} days', AppColors.textSecondary);
      case 'postpaid_window_open':
        final start = sub.paymentWindowStart != null ? fmt.format(sub.paymentWindowStart!) : '';
        final end = sub.paymentWindowEnd != null ? fmt.format(sub.paymentWindowEnd!) : '';
        final closing = days ?? 0;
        return (
          PhosphorIcons.bellRinging(),
          'Payment window: $start – $end · Closes in $closing days',
          AppColors.warning,
        );
      case 'postpaid_overdue':
        return (PhosphorIcons.warning(), 'Grace period ended ${(days ?? 0).abs()} days ago', AppColors.error);
      default:
        return (PhosphorIcons.info(), 'Tap to view payment history', AppColors.primary);
    }
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

// ── Dashboard message banners ─────────────────────────────────────────────────

class _MessageBanners extends StatelessWidget {
  const _MessageBanners({required this.banners, required this.ref});
  final List<ChatMessage> banners;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: banners
          .map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: _BannerRow(message: msg, ref: ref),
              ))
          .toList(),
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({required this.message, required this.ref});
  final ChatMessage message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isBroadcast = message.isBroadcast;
    final bgColor = isBroadcast
        ? AppColors.accent.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.10);
    final borderColor = isBroadcast
        ? AppColors.accent.withValues(alpha: 0.4)
        : AppColors.primary.withValues(alpha: 0.35);
    final iconColor = isBroadcast ? AppColors.accent : AppColors.primary;

    return GestureDetector(
      onTap: isBroadcast ? null : () => context.push(Routes.memberMessages),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.r12,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.s8),
            Icon(
              isBroadcast ? PhosphorIcons.megaphone() : PhosphorIcons.chatText(),
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: ClipRect(
                child: _MarqueeText(
                  text: message.content,
                  style: AppText.bodySmall.copyWith(color: iconColor),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            GestureDetector(
              onTap: () => ref
                  .read(dashboardBannersProvider.notifier)
                  .dismiss(message.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                child: Icon(Icons.close, size: 16, color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 60px/s scroll speed; longer text takes more time
    final duration = Duration(seconds: (widget.text.length * 0.12).round().clamp(4, 30));
    _controller = AnimationController(vsync: this, duration: duration)
      ..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        // Estimate text width: ~7px per character at bodySmall
        final textWidth = (widget.text.length * 7.5).clamp(containerWidth, double.infinity);
        final totalTravel = containerWidth + textWidth;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final offset = _animation.value * totalTravel;
            return Transform.translate(
              offset: Offset(containerWidth - offset, 0),
              child: child,
            );
          },
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

class _DietPlanCard extends StatelessWidget {
  const _DietPlanCard({required this.member});
  final Member member;

  Map<String, dynamic>? _getNextMeal(Map<String, dynamic> dietChart) {
    final isNew = dietChart.containsKey('detailed_diet_chart');
    final rawMeals = isNew
        ? (dietChart['detailed_diet_chart'] as List<dynamic>? ?? [])
        : (dietChart['meals'] as List<dynamic>? ?? []);
    if (rawMeals.isEmpty) return null;

    final meals = rawMeals.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final now = DateTime.now();

    List<(Map<String, dynamic>, DateTime)> mealTimePairs = [];

    for (final meal in meals) {
      // Support both old ('time') and new ('ideal_time') schema fields.
      // ideal_time may be a range like "7:00 AM - 8:00 AM"; take the first part.
      final raw = (meal['time'] ?? meal['ideal_time']) as String?;
      final String? timeStr = raw?.split(RegExp(r'[-–]')).first.trim();
      if (timeStr == null || timeStr.trim().isEmpty) continue;
      try {
        final cleanTime = timeStr.trim();
        final parts = cleanTime.split(RegExp(r'\s+'));
        if (parts.length != 2) continue;
        final timeParts = parts[0].split(':');
        if (timeParts.length != 2) continue;

        int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);
        final String ampm = parts[1].toUpperCase();

        if (ampm == 'PM' && hour < 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }

        DateTime mealToday = DateTime(now.year, now.month, now.day, hour, minute);
        if (mealToday.isBefore(now)) {
          mealToday = mealToday.add(const Duration(days: 1));
        }
        mealTimePairs.add((meal, mealToday));
      } catch (_) {
        // safe fallback
      }
    }

    if (mealTimePairs.isEmpty) {
      return meals.first;
    }

    mealTimePairs.sort((a, b) => a.$2.compareTo(b.$2));
    return mealTimePairs.first.$1;
  }

  @override
  Widget build(BuildContext context) {
    final chart = member.dietChart;
    final isChartActive = chart != null && chart.isNotEmpty;

    if (!isChartActive) {
      return Container(
        width: double.infinity,
        padding: AppSpacing.paddingAll24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.r24,
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.cookingPot(),
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'No Active Diet Plan',
              style: AppText.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Your diet chart is not active yet. Please contact your gym trainer to set up your personalized nutrition plan!',
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final isNewSchema = chart.containsKey('detailed_diet_chart');
    final int dailyCalories;
    if (isNewSchema) {
      final targets = chart['daily_targets'] as Map<String, dynamic>? ?? {};
      dailyCalories = (targets['target_calories'] as num?)?.toInt() ?? 2000;
    } else {
      dailyCalories = (chart['daily_calories'] as num?)?.toInt() ?? 2000;
    }
    final macros = chart['macros'] as Map<String, dynamic>? ?? {};
    final protein = isNewSchema ? ((chart['daily_targets'] as Map<String, dynamic>?)?['protein_g'] ?? 150) : macros['protein'] ?? 150;
    final carbs   = isNewSchema ? ((chart['daily_targets'] as Map<String, dynamic>?)?['carbs_g']   ?? 200) : macros['carbs']   ?? 200;
    final fats    = isNewSchema ? ((chart['daily_targets'] as Map<String, dynamic>?)?['fat_g']     ?? 65)  : macros['fats']    ?? 65;

    final nextMeal = _getNextMeal(chart);
    final String nextMealText = nextMeal != null
        ? 'Next meal at ${nextMeal['time'] ?? nextMeal['ideal_time'] ?? '08:30 AM'} — ${nextMeal['name'] ?? nextMeal['meal_name'] ?? 'Meal'}'
        : 'Tap to view your nutrition plan';

    return GestureDetector(
      onTap: () => context.push(Routes.memberDietChart, extra: member),
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingAll24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.r24,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIcons.cookingPot(),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'Active Nutrition Plan',
                      style: AppText.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  PhosphorIcons.caretRight(),
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              nextMealText,
              style: AppText.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Daily Budget: $dailyCalories kcal  ·  P: ${protein}g  C: ${carbs}g  F: ${fats}g',
              style: AppText.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
