import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/analytics_models.dart';
import '../layout/analytics_layout_spacing.dart';
import 'analytics_surface_card.dart';

/// Круговая диаграмма и легенда по категориям.
class AnalyticsCategoryChart extends ConsumerWidget {
  const AnalyticsCategoryChart({super.key, required this.stats});

  final List<CategoryStat> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    if (stats.isEmpty) {
      return AnalyticsSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AnalyticsLayoutSpacing.s16,
            horizontal: AnalyticsLayoutSpacing.s8,
          ),
          child: EmptyState(
            icon: Icons.pie_chart_outline_outlined,
            title: tr('analytics.empty_charts_title'),
            message: tr('analytics.empty_charts_message'),
          ),
        ),
      );
    }

    final total = stats.fold<double>(0, (sum, stat) => sum + stat.amount);
    final currencyCode = ref.watch(defaultCurrencyProvider);
    final formatter = NumberFormat.currency(
      locale: context.locale.toLanguageTag(),
      symbol: currencyCode,
    );

    return AnalyticsSurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(AnalyticsLayoutSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('analytics.top_categories'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: stats.take(6).map((stat) {
                    final percentage = (stat.amount / total * 100);
                    return PieChartSectionData(
                      value: stat.amount,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: Color(stat.colorValue),
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
                duration: AppMotion.screen,
                curve: AppMotion.curve,
              ),
            ),
            const SizedBox(height: AnalyticsLayoutSpacing.s16),
            ...stats.take(6).toList().asMap().entries.map((entry) {
              final stat = entry.value;
              final percentage = (stat.amount / total * 100);
              return AnimatedListItem(
                index: entry.key,
                delay: AppMotion.staggerInterval * 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(stat.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AnalyticsLayoutSpacing.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.categoryName),
                            Text(
                              '${stat.count} ${_pluralize(stat.count, 'запись', 'записи', 'записей')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatter.format(stat.amount),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _pluralize(int count, String one, String few, String many) {
    if (count % 10 == 1 && count % 100 != 11) {
      return one;
    }
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return few;
    }
    return many;
  }
}
