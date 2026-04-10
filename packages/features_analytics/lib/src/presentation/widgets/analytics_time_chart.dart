import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/analytics_models.dart';
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// График доходов и расходов по времени.
class AnalyticsTimeChart extends StatelessWidget {
  const AnalyticsTimeChart({super.key, required this.stats});

  final List<TimeStat> stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: cs.onSurfaceVariant,
        );

    if (stats.isEmpty) {
      return AnalyticsSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AnalyticsLayoutSpacing.s16,
            horizontal: AnalyticsLayoutSpacing.s8,
          ),
          child: EmptyState(
            icon: Icons.show_chart_outlined,
            title: tr('analytics.empty_charts_title'),
            message: tr('analytics.empty_charts_message'),
          ),
        ),
      );
    }

    final maxValue = stats.fold<double>(
      0,
      (max, stat) =>
          max > stat.income + stat.expenses ? max : stat.income + stat.expenses,
    );

    final incomeColor = cs.primary;
    final expenseColor = cs.error;

    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('analytics.by_time'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= stats.length) {
                            return const SizedBox.shrink();
                          }
                          final stat = stats[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: AnalyticsLayoutSpacing.s8),
                            child: Text(stat.label, style: labelStyle),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: labelStyle,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: stats.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.income);
                      }).toList(),
                      isCurved: true,
                      color: incomeColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: incomeColor.withValues(alpha: 0.12),
                      ),
                    ),
                    LineChartBarData(
                      spots: stats.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.expenses,
                        );
                      }).toList(),
                      isCurved: true,
                      color: expenseColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: expenseColor.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxValue * 1.2,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                    ),
                  ),
                ),
                duration: AppMotion.screen,
                curve: AppMotion.curve,
              ),
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: incomeColor, label: tr('analytics.income')),
                const SizedBox(width: AnalyticsLayoutSpacing.s16),
                _LegendItem(color: expenseColor, label: tr('analytics.expenses')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AnalyticsLayoutSpacing.s8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
