import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_components/ui_components.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/analytics_period_provider.dart';
import '../widgets/analytics_common.dart';
import '../widgets/analytics_period_selector.dart'
    show AnalyticsPeriodSelector, AnalyticsPeriodSelectorSheet;
import '../widgets/analytics_stats_cards.dart';
import '../widgets/analytics_insights_section.dart';
import '../widgets/analytics_forecast_card.dart';
import '../widgets/analytics_averages_card.dart';
import '../widgets/analytics_patterns_card.dart';
import '../widgets/analytics_comparison_card.dart';
import '../widgets/analytics_time_chart.dart';
import '../widgets/analytics_category_chart.dart';

/// Главная страница аналитики
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodState = ref.watch(analyticsPeriodProvider);
    final statsAsync = ref.watch(analyticsStatsProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);
    final timeStatsAsync = ref.watch(timeStatsProvider);
    final comparisonAsync = ref.watch(comparisonStatsProvider);
    final insightsAsync = ref.watch(smartInsightsProvider);
    final averagesAsync = ref.watch(averageStatsProvider);
    final patternsAsync = ref.watch(spendingPatternsProvider);
    final forecastAsync = ref.watch(forecastProvider);

    return PrimaryScaffold(
      title: tr('analytics.title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showPeriodSelector(context, ref),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(analyticsStatsProvider.future),
            ref.refresh(categoryStatsProvider.future),
            ref.refresh(timeStatsProvider.future),
            ref.refresh(comparisonStatsProvider.future),
            ref.refresh(smartInsightsProvider.future),
            ref.refresh(averageStatsProvider.future),
            ref.refresh(spendingPatternsProvider.future),
            ref.refresh(forecastProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Селектор периода
              AnimatedAnalyticsSection(
                index: 0,
                child: AnalyticsPeriodSelector(periodState: periodState),
              ),
              const SizedBox(height: 16),

              // Статистика
              AnimatedAnalyticsSection(
                index: 1,
                child: statsAsync.when(
                  data: (stats) => AnalyticsStatsCards(stats: stats),
                  loading: () => const AnalyticsLoadingCard(),
                  error: (error, _) =>
                      AnalyticsErrorCard(message: error.toString()),
                ),
              ),
              const SizedBox(height: 16),

              // Умные инсайты
              AnimatedAnalyticsSection(
                index: 2,
                child: insightsAsync.when(
                  data: (insights) => insights.isNotEmpty
                      ? AnalyticsInsightsSection(insights: insights)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Прогноз
              AnimatedAnalyticsSection(
                index: 3,
                child: forecastAsync.when(
                  data: (forecast) => forecast != null
                      ? AnalyticsForecastCard(forecast: forecast)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Сравнение с предыдущим периодом
              AnimatedAnalyticsSection(
                index: 4,
                child: comparisonAsync.when(
                  data: (comparison) {
                    if (comparison == null) {
                      return const SizedBox.shrink();
                    }
                    return AnalyticsComparisonCard(comparison: comparison);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              if (comparisonAsync.valueOrNull != null)
                const SizedBox(height: 16),

              // Средние показатели
              AnimatedAnalyticsSection(
                index: 5,
                child: averagesAsync.when(
                  data: (averages) => averages != null
                      ? AnalyticsAveragesCard(averages: averages)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Паттерны трат
              AnimatedAnalyticsSection(
                index: 6,
                child: patternsAsync.when(
                  data: (patterns) => patterns != null
                      ? AnalyticsPatternsCard(patterns: patterns)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // График по времени
              AnimatedAnalyticsSection(
                index: 7,
                child: timeStatsAsync.when(
                  data: (stats) => AnalyticsTimeChart(stats: stats),
                  loading: () => const AnalyticsLoadingCard(),
                  error: (error, _) =>
                      AnalyticsErrorCard(message: error.toString()),
                ),
              ),
              const SizedBox(height: 24),

              // График по категориям
              AnimatedAnalyticsSection(
                index: 8,
                child: categoryStatsAsync.when(
                  data: (stats) => AnalyticsCategoryChart(stats: stats),
                  loading: () => const AnalyticsLoadingCard(),
                  error: (error, _) =>
                      AnalyticsErrorCard(message: error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const AnalyticsPeriodSelectorSheet(),
    );
  }
}
