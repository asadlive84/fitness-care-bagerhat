import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/core/widgets/gym_card.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
