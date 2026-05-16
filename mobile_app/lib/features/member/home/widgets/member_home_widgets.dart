import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WeightMiniChart extends StatelessWidget {
  const WeightMiniChart({required this.data, super.key});
  final List<ChartPoint> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weight This Week', style: AppText.labelSmall),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 60,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.value);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BmiVisualizer extends StatelessWidget {
  const BmiVisualizer({
    required this.member,
    super.key,
  });

  final Member member;

  @override
  Widget build(BuildContext context) {
    final bmi = member.bmi ?? 0;
    final category = member.bmiCategory ?? 'N/A';
    Color color;
    double progress;

    if (bmi < 18.5) {
      color = Colors.blue;
      progress = (bmi / 18.5) * 0.25;
    } else if (bmi < 25) {
      color = AppColors.success;
      progress = 0.25 + ((bmi - 18.5) / 6.5) * 0.25;
    } else if (bmi < 30) {
      color = Colors.orange;
      progress = 0.5 + ((bmi - 25) / 5) * 0.25;
    } else {
      color = AppColors.error;
      progress = 0.75 + ((bmi - 30) / 10).clamp(0.0, 0.25);
    }

    return GymCard(
      padding: AppSpacing.paddingAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Body Mass Index (BMI)', style: AppText.labelSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.r8,
                ),
                child: Text(
                  category,
                  style: AppText.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(bmi.toStringAsFixed(1), style: AppText.headlineMedium.copyWith(color: color)),
              const SizedBox(width: 4),
              Text('kg/m²', style: AppText.bodySmall.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Ideal Range', style: AppText.labelSmall.copyWith(fontSize: 10)),
                  Text(member.idealWeightRange, style: AppText.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blue,
                      AppColors.success,
                      Colors.orange,
                      AppColors.error,
                    ],
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    margin: EdgeInsets.only(left: (constraints.maxWidth * progress).clamp(0, constraints.maxWidth - 8)),
                    height: 12,
                    width: 4,
                    transform: Matrix4.translationValues(0, -2, 0),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: AppSpacing.r4,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: AppSpacing.paddingAll12,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppSpacing.r12,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.lightbulb(), size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    member.bmiTip,
                    style: AppText.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeightJourneyTracker extends StatelessWidget {
  const WeightJourneyTracker({required this.data, super.key});
  final List<ChartPoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final first = data.first.value;
    final last = data.last.value;
    final diff = last - first;
    final isLoss = diff < 0;

    return GymCard(
      padding: AppSpacing.paddingAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weight Journey', style: AppText.labelSmall),
              Row(
                children: [
                  Icon(
                    isLoss ? PhosphorIcons.trendDown() : PhosphorIcons.trendUp(),
                    size: 16,
                    color: isLoss ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${diff.abs().toStringAsFixed(1)} kg ${isLoss ? 'lost' : 'gained'}',
                    style: AppText.labelSmall.copyWith(
                      color: isLoss ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              _WeightPoint(label: 'Start', value: first.toStringAsFixed(1)),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary,
                      ],
                    ),
                  ),
                ),
              ),
              _WeightPoint(label: 'Latest', value: last.toStringAsFixed(1), highlight: true),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          WeightMiniChart(data: data),
        ],
      ),
    );
  }
}

class _WeightPoint extends StatelessWidget {
  const _WeightPoint({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.titleLarge.copyWith(
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        Text(
          '$label (kg)',
          style: AppText.labelSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class MemberStatMini extends StatelessWidget {
  const MemberStatMini({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GymCard(
        padding: AppSpacing.paddingAll12,
        child: Column(
          children: [
            Text(
              value,
              style: AppText.titleLarge.copyWith(color: color),
            ),
            Text(
              unit,
              style: AppText.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.labelSmall.copyWith(fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
