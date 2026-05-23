import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DietChartDetailScreen extends StatelessWidget {
  const DietChartDetailScreen({super.key, required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final chart = member.dietChart;
    if (chart == null) {
      return const _EmptyState();
    }

    final dailyCalories = chart['daily_calories'] ?? 2000;
    final macros = chart['macros'] as Map<String, dynamic>? ?? {};
    final protein = macros['protein'] ?? 150;
    final carbs = macros['carbs'] ?? 200;
    final fats = macros['fats'] ?? 65;

    final rawMeals = chart['meals'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> meals = rawMeals
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: AppColors.textOnDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Your Premium Nutrition Plan',
          style: AppText.titleLarge.copyWith(color: AppColors.textOnDark),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingAll20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Glassmorphic Header / Macro Wheel ───────────────────
            _MacroSummaryHeader(
              calories: dailyCalories,
              protein: protein,
              carbs: carbs,
              fats: fats,
            ),
            const SizedBox(height: AppSpacing.s24),

            Text(
              'Daily Meal Schedule',
              style: AppText.titleMedium.copyWith(color: AppColors.textOnDark),
            ),
            const SizedBox(height: AppSpacing.s16),

            // ── Meals Timeline ──────────────────────────────────────────────
            if (meals.isEmpty)
              Text(
                'No meals scheduled.',
                style: AppText.bodyMedium.copyWith(color: AppColors.textHint),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meals.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s16),
                itemBuilder: (context, index) {
                  return _MealTimelineCard(
                    meal: meals[index],
                    isFirst: index == 0,
                    isLast: index == meals.length - 1,
                  );
                },
              ),
            const SizedBox(height: AppSpacing.s32),

            // ── Premium Tips Card ───────────────────────────────────────────
            _NutritionTipsCard(member: member),
            const SizedBox(height: AppSpacing.s40),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingAll24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.cookingPot(), color: AppColors.textHint, size: 64),
              const SizedBox(height: AppSpacing.s20),
              Text(
                'No Diet Plan Active',
                style: AppText.headlineMedium.copyWith(color: AppColors.textOnDark),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Your nutrition plan is not active yet. Please contact your trainer to generate a personalized diet chart.',
                textAlign: TextAlign.center,
                style: AppText.bodyMedium.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroSummaryHeader extends StatelessWidget {
  const _MacroSummaryHeader({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  final dynamic calories;
  final dynamic protein;
  final dynamic carbs;
  final dynamic fats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAll24,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppSpacing.r24,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY BUDGET',
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      Text(
                        '$calories',
                        style: AppText.monoLarge.copyWith(color: AppColors.textOnDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'kcal',
                        style: AppText.titleSmall.copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIcons.lightning(), color: AppColors.primaryLight, size: 28),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          const Divider(color: Colors.white10),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MacroProgressWheel(
                label: 'PROTEIN',
                value: '$protein g',
                color: AppColors.primaryLight,
                percentage: 0.85,
              ),
              _MacroProgressWheel(
                label: 'CARBS',
                value: '$carbs g',
                color: AppColors.info,
                percentage: 0.70,
              ),
              _MacroProgressWheel(
                label: 'FATS',
                value: '$fats g',
                color: AppColors.accent,
                percentage: 0.55,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgressWheel extends StatelessWidget {
  const _MacroProgressWheel({
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  });

  final String label;
  final String value;
  final Color color;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 52,
              width: 52,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              size: 16,
              color: color.withOpacity(0.8),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: AppText.labelSmall.copyWith(
            color: Colors.white60,
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.titleSmall.copyWith(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MealTimelineCard extends StatefulWidget {
  const _MealTimelineCard({
    required this.meal,
    required this.isFirst,
    required this.isLast,
  });

  final Map<String, dynamic> meal;
  final bool isFirst;
  final bool isLast;

  @override
  State<_MealTimelineCard> createState() => _MealTimelineCardState();
}

class _MealTimelineCardState extends State<_MealTimelineCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String mealName = widget.meal['name']?.toString() ?? 'Meal';
    final String mealTime = widget.meal['time']?.toString() ?? '08:30 AM';
    final mealCalories = widget.meal['calories'] ?? 400;
    final p = widget.meal['protein'] ?? 25;
    final c = widget.meal['carbs'] ?? 40;
    final f = widget.meal['fats'] ?? 10;
    final List<dynamic> items = (widget.meal['items'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppSpacing.r16,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Colors.white54,
          colorScheme: const ColorScheme.dark(primary: AppColors.primaryLight),
        ),
        child: ExpansionTile(
          key: PageStorageKey(mealName),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (val) {
            setState(() {
              _isExpanded = val;
            });
          },
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
            ),
            child: Text(
              mealTime,
              style: AppText.labelMedium.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            mealName,
            style: AppText.titleMedium.copyWith(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '$mealCalories kcal  ·  P: ${p}g  C: ${c}g  F: ${f}g',
            style: AppText.bodySmall.copyWith(color: AppColors.textHint),
          ),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.white10),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOMMENDED INGREDIENTS',
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.accentLight,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (items.isEmpty)
                    Text(
                      'No specific items listed.',
                      style: AppText.bodyMedium.copyWith(color: Colors.white70),
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(
                                PhosphorIcons.circle(PhosphorIconsStyle.fill),
                                size: 6,
                                color: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$item',
                                style: AppText.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ),
                          ],
                        ),
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

class _NutritionTipsCard extends StatelessWidget {
  const _NutritionTipsCard({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAll24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.25),
            AppColors.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.r24,
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.info(), color: AppColors.primaryLight, size: 24),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Nutrition Insights',
                style: AppText.titleMedium.copyWith(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Keep your meals timed regularly! Nutrition plays an active role in reaching your target goal: "${member.goal ?? 'Fitness'}". Drink at least 3-4 liters of water daily.',
            style: AppText.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
          ),
          if (member.bmiCategory != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              '💡 Tip for your ${member.bmiCategory} profile: ${member.bmiTip}',
              style: AppText.bodySmall.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
