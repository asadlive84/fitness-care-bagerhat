import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_spacing.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:fitness_care_bagerhat/features/admin/dashboard/dashboard_stats.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AttendanceChart extends StatelessWidget {
  const AttendanceChart({required this.data, super.key});
  final List<ChartPoint> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance (Daily)', style: AppText.titleMedium),
        const SizedBox(height: AppSpacing.s16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(data[index].label, style: AppText.labelSmall),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: AppColors.accent,
                      width: 16,
                      borderRadius: AppSpacing.r4,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
